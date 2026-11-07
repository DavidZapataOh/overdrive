#!/usr/bin/env bash
# Tests for overdrive pin.

od() { "$BASH" "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" "$@"; }

sq() {
  local s=$1 slash=/
  s=${s//$slash$slash/$slash}
  printf '%s' "$s"
}

# expected_pins REPO PATH...: the pins file for PATH... pinned at HEAD.
expected_pins() {
  local repo=$1 head p body
  shift
  head=$(git -C "$repo" rev-parse HEAD)
  body="sha $head"
  for p in "$@"; do
    body="$body
path $(git -C "$repo" rev-parse "$head:$p") $p"
  done
  printf '%s\nseal %s\n' "$body" "$(printf '%s\n' "$body" | cksum | cut -d' ' -f1)"
}

# tdd_repo: a repo with one committed test file whose path has a space.
tdd_repo() {
  local repo
  repo=$(make_repo)
  commit_file "$repo" "tests/cart total.test.sh" 'assert total 10'
  commit_file "$repo" src/cart.sh 'total=0'
  printf '%s\n' "$repo"
}

test_pin_requires_committed_tests() {
  local repo rc
  repo=$(tdd_repo)
  write_file "$repo" tests/new.test.sh 'new'
  rc=0; (cd "$repo/tests" && od pin new.test.sh) >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc" untracked
  git -C "$repo" add tests/new.test.sh
  rc=0; (cd "$repo/tests" && od pin new.test.sh) >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc" "staged, not committed"
  git -C "$repo" commit -q -m new
  printf 'changed\n' >> "$repo/tests/new.test.sh"
  rc=0; (cd "$repo/tests" && od pin new.test.sh) >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc" "modified in the working tree"
  [ ! -f "$repo/.overdrive/run/pins" ]
  git -C "$repo" checkout -q -- tests/new.test.sh
  (cd "$repo/tests" && od pin new.test.sh "cart total.test.sh") >/dev/null
  assert_eq "$(expected_pins "$repo" "tests/cart total.test.sh" tests/new.test.sh)" "$(cat "$repo/.overdrive/run/pins")"
}

test_pin_directory_and_merge_with_existing_pins() {
  local repo first
  repo=$(tdd_repo)
  commit_file "$repo" tests/unit/a.test.sh a
  commit_file "$repo" tests/unit/b.test.sh b
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  first=$(git -C "$repo" rev-parse HEAD)
  assert_line "$(cat "$repo/.overdrive/run/pins")" "sha $first"
  commit_file "$repo" src/other.sh other
  (cd "$repo" && od pin tests/unit) >/dev/null
  assert_eq "$(expected_pins "$repo" "tests/cart total.test.sh" tests/unit/a.test.sh tests/unit/b.test.sh)" \
    "$(cat "$repo/.overdrive/run/pins")"
  # A pinned test edited and committed since its pin cannot be laundered by re-pinning.
  printf 'weaker\n' > "$repo/tests/unit/a.test.sh"
  git -C "$repo" commit -q -am weaken
  local rc=0
  (cd "$repo" && od pin tests/unit/b.test.sh) >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
}

test_pin_status_reports_changes() {
  local repo out rc=0
  repo=$(tdd_repo)
  out=$(cd "$repo" && od pin --status)
  assert_eq 'no pins' "$out"
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  out=$(cd "$repo" && od pin --status)
  assert_line "$out" 'unchanged tests/cart total.test.sh'
  printf 'x\n' >> "$repo/tests/cart total.test.sh"
  out=$(cd "$repo" && od pin --status) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" 'changed tests/cart total.test.sh'
}

test_release_writes_reason_to_ledger() {
  local repo run rc=0
  repo=$(tdd_repo)
  run=$repo/.overdrive/run
  mkdir -p "$run/my-plan"
  printf '# Overdrive ledger — plan: /x/my-plan.md\nTask 1: in-progress\n' > "$run/my-plan/ledger.md"
  printf 'my-plan/ledger.md\n' > "$run/active-ledger"
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  (cd "$repo" && od pin --release) >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc" "a reason is required"
  [ -f "$run/pins" ]
  (cd "$repo" && od pin --release 'the test asserted the wrong total') >/dev/null
  [ ! -f "$run/pins" ]
  assert_eq 'Note: pins released — the test asserted the wrong total' "$(sed -n '$p' "$run/my-plan/ledger.md")"
  assert_eq 3 "$(wc -l < "$run/my-plan/ledger.md" | tr -d ' ')"
  # Without an active ledger the pins are still released.
  rm "$run/active-ledger"
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  (cd "$repo" && od pin --release 'second reason') >/dev/null
  [ ! -f "$run/pins" ]
  assert_eq 3 "$(wc -l < "$run/my-plan/ledger.md" | tr -d ' ')"
}

test_clear_requires_green_evidence() {
  local repo rc=0
  repo=$(tdd_repo)
  # A sha in captured output is not a header: it must not satisfy the check.
  (cd "$repo" && od evidence green -- sh -c "echo 'Pin: $(git -C "$repo" rev-parse HEAD)'") >/dev/null
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  (cd "$repo" && od pin --clear) >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
  [ -f "$repo/.overdrive/run/pins" ]
  (cd "$repo" && od evidence green -- true) >/dev/null
  (cd "$repo" && od pin --clear) >/dev/null
  [ ! -f "$repo/.overdrive/run/pins" ]
}

test_pin_outside_git_fails() {
  mkdir plain
  local rc=0
  (cd plain && od pin x) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
}

# pin_then_weaken REPO: pin two committed tests, then commit a weakened first one.
pin_then_weaken() {
  commit_file "$1" tests/other.test.sh other
  (cd "$1" && od pin "tests/cart total.test.sh" tests/other.test.sh) >/dev/null
  printf 'weaker\n' > "$1/tests/cart total.test.sh"
  git -C "$1" commit -q -am weaken
}

# assert_pins_invalid REPO: status and green both refuse, naming release as the way out.
assert_pins_invalid() {
  local out rc=0
  out=$(cd "$1" && od pin --status 2>&1) || rc=$?
  assert_eq 65 "$rc" "$2"
  case $out in *"pin --release"*) ;; *) echo "no release hint: $out" >&2; return 1 ;; esac
  rc=0
  (cd "$1" && od evidence green -- true) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc" "$2"
}

test_pins_hand_edited_sha_fails_closed() {
  local repo pins
  repo=$(tdd_repo)
  pin_then_weaken "$repo"
  pins=$repo/.overdrive/run/pins
  # Re-point the pins at the commit that weakened the test.
  { printf 'sha %s\n' "$(git -C "$repo" rev-parse HEAD)"; sed 1d "$pins"; } > "$pins.new"
  mv "$pins.new" "$pins"
  assert_pins_invalid "$repo" "edited sha"
  # Even with a matching seal the stored blobs no longer match the new sha.
  sed '$d' "$pins" > "$pins.body"
  { cat "$pins.body"; printf 'seal %s\n' "$(cksum < "$pins.body" | cut -d' ' -f1)"; } > "$pins"
  assert_pins_invalid "$repo" "edited sha with a recomputed seal"
}

test_pins_deleted_path_line_fails_closed() {
  local repo pins
  repo=$(tdd_repo)
  pin_then_weaken "$repo"
  pins=$repo/.overdrive/run/pins
  grep -v 'cart total' "$pins" > "$pins.new"
  mv "$pins.new" "$pins"
  assert_pins_invalid "$repo" "deleted path line"
}

test_pins_amended_pin_commit_fails_closed() {
  local repo
  repo=$(tdd_repo)
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  # Rewriting the pinned commit leaves the pin sha outside HEAD's history.
  git -C "$repo" commit -q --amend -m rewritten
  assert_pins_invalid "$repo" "amended pin commit"
}

test_pins_git_mv_of_pinned_test_is_a_change() {
  local repo rc=0 out
  repo=$(tdd_repo)
  (cd "$repo" && od pin "tests/cart total.test.sh") >/dev/null
  git -C "$repo" mv "tests/cart total.test.sh" tests/renamed.test.sh
  out=$(cd "$repo" && od pin --status) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" 'changed tests/cart total.test.sh'
  git -C "$repo" commit -q -m rename
  rc=0
  (cd "$repo" && od evidence green -- true) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
}
