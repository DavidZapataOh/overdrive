#!/usr/bin/env bash
# Tests for overdrive risk: every failure to classify is reported as critical.
# shellcheck disable=SC2016  # wrapper scripts are written with literal $ expansions

# shellcheck source=helpers.sh
. "$(dirname "$RUNNER")/risk/helpers.sh"

# assert_failed_closed [REASON]: $out and $rc are a fail-closed classification.
assert_failed_closed() {
  assert_eq 3 "$rc" "exit code"
  assert_eq "lane critical" "$(printf '%s\n' "$out" | head -n 1)"
  if [ -n "${1:-}" ]; then
    assert_line "$out" "item classification-failed critical failure $1"
  else
    assert_line "$out" "$(printf '%s\n' "$out" | grep '^item classification-failed critical failure .')"
  fi
  assert_line "$out" "next Full TDD plan approved by the user; per-task critical review and final review."
  assert_eq "Risk: critical — classification-failed" "$(risk_line)"
}

test_fail_closed_on_invalid_map() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/a.ts
  printf 'path src/** admin high\n' > map.conf
  risk "$repo" --worktree --map "$PWD/map.conf"
  assert_failed_closed "invalid risk map"
  # An invalid map on either side of a change fails too.
  write_file "$repo" .overdrive/risk-map.conf 'content "a{,2}" bad'
  commit_all "$repo" bad-map
  write_file "$repo" .overdrive/risk-map.conf 'pathtoken fine fine'
  risk "$repo" --worktree
  assert_failed_closed "invalid risk map"
  # Before work too: the committed map counts even when the working tree's is valid.
  risk "$repo" --intent "x"
  assert_failed_closed "invalid risk map"
}

test_fail_closed_on_unborn_head() {
  local repo=$PWD/unborn mode
  git init -q "$repo"
  write_file "$repo" src/a.ts 'x'
  git -C "$repo" add -A
  for mode in --staged --worktree '--intent x' '--diff HEAD~1..HEAD'; do
    # shellcheck disable=SC2086
    risk "$repo" $mode
    assert_failed_closed "no commits yet"
  done
}

test_fail_closed_outside_git() {
  mkdir plain
  rc=0
  out=$(cd plain && GIT_CEILING_DIRECTORIES=$PWD overdrive risk --worktree 2>/dev/null) || rc=$?
  assert_failed_closed "not a git repository"
  rc=0
  out=$(overdrive risk --repo "$PWD/plain" --intent "x" 2>/dev/null) || rc=$?
  assert_failed_closed "not a git repository"
}

test_shallow_clone_range_missing_fails_closed() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/a.ts
  commit_all "$repo" one
  printf '// two\n' >> "$repo/src/a.ts"
  commit_all "$repo" two
  git clone -q --depth 1 "file://$repo" shallow
  risk "$PWD/shallow" --diff HEAD~1..HEAD
  assert_failed_closed
  assert_line "$out" "$(printf '%s\n' "$out" | grep '^item classification-failed critical failure cannot read HEAD~1')"
  git clone -q --depth 2 "file://$repo" deeper
  risk "$PWD/deeper" --diff HEAD~1..HEAD
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_eq "Risk: direct — none" "$(risk_line)"
}

test_worktree_git_file() {
  local repo wt base log
  repo=$(make_repo)
  source_with_test "$repo" src/a.ts
  commit_all "$repo" base
  wt=$PWD/linked
  git -C "$repo" worktree add -q -b topic "$wt"
  [ -f "$wt/.git" ]
  printf 'const m = new Mutex();\n' >> "$wt/src/a.ts"
  source_with_test "$wt" src/billing/fee.ts
  risk "$wt" --worktree
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item concurrency critical floor line src/a.ts:2"
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
  git -C "$wt" add -A
  risk "$wt" --staged
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item concurrency critical floor line src/a.ts:2"
  git -C "$wt" commit -q -m topic
  base=$(git -C "$repo" symbolic-ref --short HEAD)
  log=$PWD/err
  rc=0
  out=$(cd "$wt/src" && overdrive risk --diff "$base..topic" 2>"$log") || rc=$?
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_eq "Risk: critical — concurrency, money" "$(risk_line)"
  # The main checkout's index is untouched by the linked one's classification.
  assert_eq "" "$(git -C "$repo" status --porcelain)"
}

test_missing_range_fails_closed() {
  local repo
  repo=$(make_repo)
  risk "$repo" --diff HEAD..no-such-branch
  assert_failed_closed
}

test_library_failure_fails_closed() {
  local repo root
  root=$(dirname "$(dirname "$RUNNER")")
  repo=$(make_repo)
  source_with_test "$repo" src/a.ts
  mkdir -p home/lib
  cp "$root"/plugins/overdrive/lib/* home/lib/
  printf '\nsignals_changes() { return 1; }\n' >> home/lib/signals.sh
  rc=0
  out=$(OVERDRIVE_HOME=$PWD/home "$root/plugins/overdrive/libexec/overdrive-risk" \
    --repo "$repo" --worktree 2>err) || rc=$?
  assert_failed_closed
}

# Each external command the classifier runs is made to fail in turn; every one of
# those failures must end in the fail-closed classification, never in a lower lane.
test_every_failing_command_fails_closed() {
  local repo n=0 calls tool real args clean
  args='--diff HEAD~1..HEAD --diff HEAD~1...HEAD --staged --worktree --intent cobro'
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'keyword cobro money'
  write_file "$repo" src/a.ts 'x'
  commit_all "$repo" base
  printf '// cobro\n' >> "$repo/src/a.ts"
  write_file "$repo" src/new.ts 'y'
  git -C "$repo" add src/new.ts
  write_file "$repo" src/untracked.ts 'z'
  mkdir -p fake calls
  echo 0 > calls/fail
  # The wrapper numbers its call with an exclusive create (noclobber) using builtins
  # only, so concurrent calls in a pipeline never share a number.
  for tool in git awk sort tr wc cat cp mktemp; do
    real=$(command -v "$tool")
    {
      printf '#!/usr/bin/env bash\nset -C\nn=1\n'
      printf 'while ! true 2>/dev/null > "%s/calls/$n"; do n=$((n + 1)); done\n' "$PWD"
      printf 'read -r fail < "%s/calls/fail"\n' "$PWD"
      printf 'if [ "$n" = "$fail" ]; then echo %s > "%s/calls/injected"; echo "injected failure in %s" >&2; exit 2; fi\n' "$tool" "$PWD" "$tool"
      printf 'exec "%s" "$@"\n' "$real"
    } > "fake/$tool"
    chmod +x "fake/$tool"
  done
  rc=0
  # shellcheck disable=SC2086
  out=$(PATH=$PWD/fake:$PATH overdrive risk --repo "$repo" $args 2>err) || rc=$?
  assert_eq 0 "$rc" "clean run: $(cat err)"
  assert_line "$out" 'item money critical map keyword "cobro"'
  clean=$out
  calls=0
  while [ -e "calls/$((calls + 1))" ]; do calls=$((calls + 1)); done
  [ "$calls" -gt 10 ]
  while [ "$n" -lt "$calls" ]; do
    n=$((n + 1))
    rm -f calls/*
    echo "$n" > calls/fail
    rc=0
    # shellcheck disable=SC2086
    out=$(PATH=$PWD/fake:$PATH overdrive risk --repo "$repo" $args 2>err) || rc=$?
    echo "failure injected at call $n of $calls: $(cat err)" >&2
    # A work directory that cannot be made in TMPDIR is made in the repository instead;
    # the run must then classify exactly as the clean one did.
    if [ "$(cat calls/injected)" = mktemp ] && [ "$rc" -eq 0 ]; then
      assert_eq "$clean" "$out"
      continue
    fi
    assert_failed_closed
  done
}

test_merge_in_progress_staged() {
  local repo base
  repo=$(make_repo)
  source_with_test "$repo" src/a.ts
  commit_all "$repo" base
  base=$(git -C "$repo" symbolic-ref --short HEAD)
  git -C "$repo" checkout -q -b topic
  printf 'export const b = 1;\n' > "$repo/src/a.ts"
  git -C "$repo" commit -q -am topic
  git -C "$repo" checkout -q "$base"
  printf 'export const c = 1;\n' > "$repo/src/a.ts"
  git -C "$repo" commit -q -am main
  git -C "$repo" merge -q topic >/dev/null 2>&1 || true
  risk "$repo" --staged
  assert_failed_closed
  assert_line "$out" "$(printf '%s\n' "$out" | grep '^item classification-failed critical failure .*unmerged paths')"
}

# Sandboxed shells can hand out a TMPDIR nobody may write to, and sometimes no writable
# /tmp either. The classifier then works inside the repository's self-ignoring run
# directory instead of failing every change.
test_unwritable_tmp_uses_the_repository_run_dir() {
  local repo left real fake=$PWD/fake missing=$PWD/missing
  repo=$(make_repo)
  write_file "$repo" README.md 'receive'
  # mktemp refuses every template outside the repository.
  mkdir fake
  real=$(command -v mktemp)
  printf '#!/usr/bin/env bash
case "$*" in *"%s"/*) exec "%s" "$@" ;; esac
exit 1
' "$repo" "$real" > fake/mktemp
  chmod +x fake/mktemp
  rc=0
  out=$(cd "$repo" && PATH=$fake:$PATH TMPDIR=$missing overdrive risk --worktree 2>err) || rc=$?
  assert_eq 0 "$rc" "exit code"
  assert_eq "Risk: direct — none" "$(risk_line)"
  left=$(cd "$repo/.overdrive/run" && ls -A)
  assert_eq ".gitignore" "$left"
  # Before work too, with the repository named instead of found from the directory.
  rc=0
  out=$(PATH=$fake:$PATH TMPDIR=$missing overdrive risk --repo "$repo" --intent 'fix a typo' --paths README.md 2>err) || rc=$?
  assert_eq 0 "$rc" "exit code"
  assert_eq "Risk: direct — none" "$(risk_line)"
}
