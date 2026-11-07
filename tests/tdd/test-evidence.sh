#!/usr/bin/env bash
# Tests for overdrive evidence.

od() { "$BASH" "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" "$@"; }

sq() {
  local s=$1 slash=/
  s=${s//$slash$slash/$slash}
  printf '%s' "$s"
}

pinned_repo() {
  local repo
  repo=$(make_repo)
  commit_file "$repo" "tests/cart total.test.sh" 'assert total 10'
  commit_file "$repo" src/cart.sh 'total=0'
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  printf '%s\n' "$repo"
}

test_red_rejects_passing_command() {
  local repo out rc=0
  repo=$(pinned_repo)
  out=$(cd "$repo" && od evidence red -- true) || rc=$?
  assert_eq 1 "$rc"
  assert_eq 'not red: the test passed before the change' "$out"
  [ -z "$(ls "$repo/.overdrive/run/evidence" 2>/dev/null)" ]
  # A command that cannot run is not a failing test.
  rc=0
  (cd "$repo" && od evidence red -- ./no-such-command) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
  [ -z "$(ls "$repo/.overdrive/run/evidence" 2>/dev/null)" ]
}

test_red_records_failure_output() {
  local repo out file body
  repo=$(pinned_repo)
  # shellcheck disable=SC2016
  out=$(cd "$repo/src" && od evidence red -- sh -c 'i=0; while [ $i -lt 50 ]; do echo "line $i"; i=$((i+1)); done; echo "boom | it" >&2; exit 3')
  file=$(sq "$repo")/.overdrive/run/evidence/0001-red.md
  assert_eq "$file" "$out"
  body=$(cat "$file")
  assert_line "$body" '# Evidence: red'
  assert_line "$body" 'Exit: 3'
  assert_line "$body" "Head: $(git -C "$repo" rev-parse HEAD)"
  assert_line "$body" "Pin: $(git -C "$repo" rev-parse HEAD)"
  assert_line "$body" 'Directory: src'
  assert_file_contains "$file" '^Command: sh -c '
  assert_file_contains "$file" '^Time: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
  # The last 40 lines of combined output, verbatim.
  assert_line "$body" 'line 11'
  assert_line "$body" 'line 49'
  assert_line "$body" 'boom | it'
  assert_no_line "$body" '^line 10$'
  assert_eq 'boom | it' "$(sed -n '$p' "$file")"
  assert_eq 40 "$(sed -n '/^## Output/,$p' "$file" | sed '1,2d' | wc -l | tr -d ' ')"
}

test_green_rejects_modified_pinned_test() {
  local repo out rc
  repo=$(pinned_repo)
  # Unstaged.
  printf 'weaker\n' > "$repo/tests/cart total.test.sh"
  rc=0; out=$(cd "$repo" && od evidence green -- true 2>&1) || rc=$?
  assert_eq 1 "$rc" unstaged
  case $out in *"tests/cart total.test.sh"*) ;; *) echo "out: $out" >&2; return 1 ;; esac
  # Staged, then put back in the working tree: the index still differs.
  git -C "$repo" add -A
  git -C "$repo" show "HEAD:tests/cart total.test.sh" > "$repo/tests/cart total.test.sh"
  rc=0; (cd "$repo" && od evidence green -- true) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc" staged
  # Committed.
  printf 'weaker\n' > "$repo/tests/cart total.test.sh"
  git -C "$repo" commit -q -am weaken
  rc=0; (cd "$repo" && od evidence green -- true) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc" committed
  # Deleted.
  git -C "$repo" reset -q --hard HEAD~1
  rm "$repo/tests/cart total.test.sh"
  rc=0; (cd "$repo" && od evidence green -- true) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc" deleted
  [ -z "$(ls "$repo/.overdrive/run/evidence" 2>/dev/null)" ]
}

test_green_records_success() {
  local repo out rc=0
  repo=$(pinned_repo)
  rc=0; out=$(cd "$repo" && od evidence green -- sh -c 'echo failing; exit 1') || rc=$?
  assert_eq 1 "$rc"
  case $out in "not green"*) ;; *) echo "out: $out" >&2; return 1 ;; esac
  printf 'total=10\n' > "$repo/src/cart.sh"
  git -C "$repo" commit -q -am fix
  out=$(cd "$repo" && od evidence green -- sh -c 'echo all passed')
  assert_eq "$(sq "$repo")/.overdrive/run/evidence/0001-green.md" "$out"
  assert_file_contains "$out" '^Exit: 0$'
  assert_file_contains "$out" '^all passed$'
  assert_file_contains "$out" "^Pin: $(git -C "$repo" rev-parse HEAD~1)$"
}

test_evidence_without_pins() {
  local repo out
  repo=$(make_repo)
  out=$(cd "$repo" && od evidence green -- true)
  assert_file_contains "$out" '^Pin: none$'
}

test_evidence_ids_unique_under_parallel_runs() {
  local repo i od_bin
  repo=$(pinned_repo)
  od_bin=$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive
  # Waiters on a loaded machine must not give up before the holders finish.
  export OD_LOCK_TIMEOUT=60
  # Separate processes, each with its own pid, as parallel sessions would be.
  for i in 1 2 3 4 5; do
    # shellcheck disable=SC2016
    (cd "$repo" && "$BASH" -c '"$BASH" "$1" evidence red -- sh -c "echo run $2; exit 1"' _ "$od_bin" "$i") > "out$i" 2>&1 &
  done
  wait
  for i in 1 2 3 4 5; do
    [ -f "$(cat "out$i")" ] || { cat "out$i" >&2; return 1; }
  done
  assert_eq '0001-red.md 0002-red.md 0003-red.md 0004-red.md 0005-red.md' \
    "$(cd "$repo/.overdrive/run/evidence" && echo [0-9]*)"
  assert_eq 5 "$(cat out1 out2 out3 out4 out5 | sort -u | wc -l | tr -d ' ')"
  for i in 1 2 3 4 5; do
    assert_eq 1 "$(grep -l -x "run $i" "$repo"/.overdrive/run/evidence/*.md | wc -l | tr -d ' ')"
  done
}

test_evidence_list() {
  local repo out
  repo=$(pinned_repo)
  assert_eq '' "$(cd "$repo" && od evidence list)"
  (cd "$repo" && od evidence red -- false) >/dev/null
  (cd "$repo" && od evidence green -- true) >/dev/null
  out=$(cd "$repo" && od evidence list)
  assert_eq "$(sq "$repo")/.overdrive/run/evidence/0001-red.md
$(sq "$repo")/.overdrive/run/evidence/0002-green.md" "$out"
}

test_red_rejects_modified_pinned_test() {
  local repo out rc=0
  repo=$(pinned_repo)
  printf 'weaker\n' > "$repo/tests/cart total.test.sh"
  out=$(cd "$repo" && od evidence red -- false) || rc=$?
  assert_eq 1 "$rc"
  assert_eq 'not red: pinned test changed: tests/cart total.test.sh' "$out"
}

test_green_rejects_command_that_rewrites_pinned_test() {
  local repo rc=0
  repo=$(pinned_repo)
  # shellcheck disable=SC2016
  (cd "$repo" && od evidence green -- sh -c 'echo x >> "tests/cart total.test.sh"') >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
  [ -z "$(ls "$repo/.overdrive/run/evidence" 2>/dev/null)" ]
}

test_green_fails_closed_on_corrupt_pins() {
  local repo rc=0
  repo=$(pinned_repo)
  printf 'garbage\n' > "$repo/.overdrive/run/pins"
  (cd "$repo" && od evidence green -- true) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
  # Release is the way out of a corrupt pins file.
  (cd "$repo" && od pin --release 'pins file was corrupt') >/dev/null
  (cd "$repo" && od evidence green -- true) >/dev/null
}

test_evidence_never_overwrites_a_record() {
  local repo dir out f
  repo=$(pinned_repo)
  dir=$repo/.overdrive/run/evidence
  # Something already sits at the next id without being a record the scan counts: the
  # placement must refuse it and take the following id, never write into or over it.
  mkdir -p "$dir/0001-red.md"
  out=$(cd "$repo" && od evidence red -- false)
  assert_eq "$(sq "$repo")/.overdrive/run/evidence/0002-red.md" "$out"
  assert_eq '' "$(ls -A "$dir/0001-red.md")"
  for f in "$dir"/.*tmp "$dir"/*tmp; do
    [ ! -e "$f" ] || { echo "left behind: $f" >&2; return 1; }
  done
}

test_evidence_cleans_up_when_interrupted() {
  local repo pid i
  repo=$(pinned_repo)
  mkdir tmp
  (cd "$repo" && TMPDIR=$OLDPWD/tmp exec "$BASH" "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" evidence red -- sleep 30) >/dev/null 2>&1 &
  pid=$!
  for i in $(seq 1 100); do
    [ -z "$(ls tmp)" ] || break
    sleep 0.1
  done
  [ -n "$(ls tmp)" ] || { echo "evidence never started" >&2; return 1; }
  kill -TERM "$pid"
  i=0
  wait "$pid" || i=$?
  [ "$i" -ne 0 ]
  assert_eq '' "$(ls tmp)"
  [ -z "$(ls "$repo/.overdrive/run/evidence" 2>/dev/null)" ]
}
