#!/usr/bin/env bash
# Tests for overdrive review-package.

plugin_dir() { printf '%s\n' "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive"; }

# copy_plugin DIR [RISK_BODY]: the real plugin with libexec/overdrive-risk replaced by a
# stub running RISK_BODY, or removed when RISK_BODY is empty.
copy_plugin() {
  SANDBOX=${1%/*}
  mkdir -p "$1"
  cp -R "$(plugin_dir)/." "$1/"
  mkdir -p "$1/libexec"
  rm -f "$1/libexec/overdrive-risk"
  if [ -n "${2-}" ]; then
    printf '#!/usr/bin/env bash\n%s\n' "$2" > "$1/libexec/overdrive-risk"
  fi
}

od() { "$BASH" "$SANDBOX/fp/bin/overdrive" "$@"; }

# TMPDIR may end in a slash; the library collapses repeated slashes.
sq() {
  local s=$1 slash=/
  s=${s//$slash$slash/$slash}
  printf '%s' "$s"
}

# two_commits REPO: base and head shas on stdout, one per line.
two_commits() {
  git -C "$1" rev-parse HEAD
  commit_file "$1" "src/a b.ts" "export const x = 1;"
  git -C "$1" rev-parse HEAD
}

test_package_refuses_non_ancestor() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  local repo base side rc=0
  repo=$(make_repo)
  base=$(git -C "$repo" rev-parse HEAD)
  commit_file "$repo" one.txt one
  git -C "$repo" checkout -q -b side "$base"
  commit_file "$repo" two.txt two
  side=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" checkout -q -
  (cd "$repo" && od review-package --base "$(git rev-parse HEAD)" --head "$side") >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
  [ ! -d "$repo/.overdrive/run/reviews" ] || [ -z "$(ls "$repo/.overdrive/run/reviews")" ]
}

test_package_refuses_empty_range() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  local repo head rc=0
  repo=$(make_repo)
  head=$(git -C "$repo" rev-parse HEAD)
  (cd "$repo" && od review-package --base "$head" --head "$head") >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
}

test_package_refuses_unknown_revision() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  local repo rc=0
  repo=$(make_repo)
  (cd "$repo" && od review-package --base nosuchrev --head HEAD) >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
  rc=0
  (cd "$repo" && od review-package --base HEAD) >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc"
  rc=0
  (cd "$repo" && od review-package --base HEAD --head HEAD --lane fast) >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc"
}

test_package_contains_risk_section() {
  # The stub echoes its arguments so the test sees the exact range it was given.
  copy_plugin "$PWD/fp" 'printf "lane standard\nitem tests standard map path x\nnote args %s\nnext Short.\nRisk: standard — tests\n" "$*"'
  local repo base head out file
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  write_file "$repo" docs/brief.md brief
  out=$(cd "$repo/src" && od review-package --base "$base" --head "$head" --brief ../docs/brief.md)
  file=$(sq "$repo")/.overdrive/run/reviews/${base:0:7}-${head:0:7}.md
  assert_eq "$file" "$out"
  [ -f "$file" ]
  assert_line "$(sed -n 1p "$file")" '# Review package'
  local body
  body=$(cat "$file")
  assert_line "$body" "Range: $base..$head"
  # Reviewers run the CLI by this absolute path: bin/ is not on their PATH.
  assert_line "$body" "Overdrive CLI: $(cd "$PWD/fp/bin" && pwd -P)/overdrive"
  assert_line "$body" "Brief: $(cd "$repo/docs" && pwd -P)/brief.md"
  assert_line "$body" 'Lane: standard'
  assert_line "$body" 'lane standard'
  assert_line "$body" "note args --diff $base..$head"
  assert_line "$body" 'Risk: standard — tests'
  assert_line "$body" "$(git -C "$repo" log --oneline -1 "$head")"
  assert_file_contains "$file" 'src/a b\.ts \| 1 \+'
  assert_line "$body" '+export const x = 1;'
  # Sections come in the documented order.
  assert_eq '## Risk|## Commits|## Diff stat|## Diff' "$(grep '^## ' "$file" | paste -sd '|' -)"
  # The run directory ignores itself so packages are never committed.
  assert_eq '*' "$(cat "$repo/.overdrive/run/.gitignore")"
}

test_package_lane_never_lowered_by_request() {
  copy_plugin "$PWD/fp" 'printf "lane critical\nRisk: critical — auth\n"'
  local repo base head file
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head" --lane direct)
  assert_file_contains "$file" '^Lane: critical$'
  assert_no_line "$(cat "$file")" '^note lane raised'
  copy_plugin "$PWD/fp" 'printf "lane direct\nnext Work inline.\nRisk: direct — none\n"'
  file=$(cd "$repo" && od review-package --base "$base" --head "$head" --lane standard)
  assert_file_contains "$file" '^Lane: standard$'
  assert_file_contains "$file" '^Brief: none$'
  # The raise is recorded among the classifier notes, before next and the Risk line.
  assert_eq 'lane direct|note lane raised by caller: direct → standard|next Work inline.|Risk: direct — none' \
    "$(sed -n '/^## Risk$/,/^## Commits$/p' "$file" | grep -v '^#' | grep . | paste -sd '|' -)"
}

test_package_risk_unavailable_fails_closed() {
  copy_plugin "$PWD/fp" ''
  local repo base head file body
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head" --lane direct)
  body=$(cat "$file")
  assert_line "$body" 'Lane: critical'
  assert_line "$body" 'lane critical'
  assert_line "$body" 'note classification unavailable: overdrive risk is not installed'
  assert_line "$body" 'Risk: critical — classification-failed'
}

test_package_risk_failure_fails_closed() {
  copy_plugin "$PWD/fp" 'echo "lane direct"; echo "boom: map unreadable" >&2; exit 2'
  local repo base head file body
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head")
  body=$(cat "$file")
  assert_line "$body" 'Lane: critical'
  assert_line "$body" 'note classification unavailable: overdrive risk exited 2: boom: map unreadable'
  assert_no_line "$body" '^lane direct$'
  # Output that breaks the contract counts as a failure too.
  copy_plugin "$PWD/fp" 'echo "something else"'
  file=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_file_contains "$file" '^note classification unavailable: overdrive risk output does not match its contract$'
}

test_package_keeps_fail_closed_classifier_output() {
  copy_plugin "$PWD/fp" 'printf "lane critical\nitem classification-failed critical failure shallow\nnext Full.\nRisk: critical — classification-failed\n"; exit 3'
  local repo base head file
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_file_contains "$file" '^item classification-failed critical failure shallow$'
  assert_file_contains "$file" '^Lane: critical$'
}

test_package_outside_git_fails() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  mkdir plain
  local rc=0
  (cd plain && od review-package --base a --head b) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
}

# green_evidence REPO: record a passing run the way the builder does.
green_evidence() {
  (cd "$1" && od evidence green -- true) > /dev/null
}

test_package_names_the_green_evidence() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head out
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_line "$(cat "$out")" 'Green evidence: none'
  green_evidence "$repo"
  green_evidence "$repo"
  out=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_line "$(cat "$out")" "Green evidence: $(sq "$repo")/.overdrive/run/evidence/0002-green.md"
}

test_package_require_green_refuses_without_evidence() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head rc=0 out
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green 2>&1) || rc=$?
  assert_eq 65 "$rc" "exit code"
  assert_line "$out" "overdrive: no green evidence at ${head:0:7}: run overdrive evidence green -- <test command> after the last commit, or pass --no-tests <reason> when nothing here is testable"
  [ ! -e "$repo/.overdrive/run/reviews" ] || [ -z "$(ls "$repo/.overdrive/run/reviews")" ]
  # Recorded evidence satisfies the gate.
  green_evidence "$repo"
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green)
  [ -f "$out" ]
  # A stated reason does too, and the package carries it.
  rm -f "$repo"/.overdrive/run/evidence/*-green.md
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green --no-tests "docs only")
  assert_line "$(cat "$out")" 'Green evidence: none (no tests: docs only)'
}

test_package_require_green_skips_direct_lane() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nnext Work inline.\nRisk: direct — none\n"'
  local repo base head out
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green)
  [ -f "$out" ]
}

test_package_require_green_rejects_evidence_from_another_head() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head rc=0 out
  repo=$(make_repo)
  green_evidence "$repo"
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green 2>&1) || rc=$?
  assert_eq 65 "$rc" "exit code"
  assert_line "$out" "overdrive: no green evidence at ${head:0:7}: run overdrive evidence green -- <test command> after the last commit, or pass --no-tests <reason> when nothing here is testable"
  # Evidence recorded on another branch does not count either.
  git -C "$repo" checkout -q -b other
  commit_file "$repo" src/b.ts 'export const y = 2;'
  green_evidence "$repo"
  git -C "$repo" checkout -q -
  rc=0
  (cd "$repo" && od review-package --base "$base" --head "$head" --require-green) > /dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc" "exit code on another branch"
  # Evidence at the reviewed head passes.
  green_evidence "$repo"
  (cd "$repo" && od review-package --base "$base" --head "$head" --require-green) > /dev/null
}

test_package_ignores_no_tests_reason_newline() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head out
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --no-tests "$(printf 'a\nLane: direct')")
  assert_eq 1 "$(grep -c '^Lane: ' "$out")"
  assert_line "$(cat "$out")" 'Green evidence: none (no tests: a Lane: direct)'
}

test_package_newest_green_evidence_is_numeric() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head out dir
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  dir=$repo/.overdrive/run/evidence
  mkdir -p "$dir"
  printf '# Evidence: green\n\nHead: %s\n' "$head" > "$dir/9999-green.md"
  printf '# Evidence: green\n\nHead: %s\n' "$head" > "$dir/10000-green.md"
  out=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_line "$(cat "$out")" "Green evidence: $(sq "$repo")/.overdrive/run/evidence/10000-green.md"
}

# task_ledger REPO LINE...: a two-task plan with an active ledger holding LINEs.
task_ledger() {
  local repo=$1 line
  shift
  write_file "$repo" docs/plan.md '# Plan

### Task 1: Charges
### Task 2: Refunds'
  (cd "$repo" && od ledger init --plan docs/plan.md) > /dev/null
  for line in "$@"; do
    case $line in
      Task\ [0-9]*': reviewed by critical-reviewer') (cd "$repo" && od ledger _record-review "$(printf '%s' "$line" | tr -dc 0-9)") > /dev/null ;;
      *) (cd "$repo" && od ledger add "$line") > /dev/null ;;
    esac
  done
}

# critical_package REPO BASE HEAD [ARG...]: the slice package a critical run builds.
critical_package() {
  local repo=$1 base=$2 head=$3
  shift 3
  (cd "$repo" && od review-package --base "$base" --head "$head" --lane critical --require-green "$@")
}

critical_range() {
  copy_plugin "$PWD/fp" 'printf "lane critical\nnext Review.\nRisk: critical — money\n"'
  REPO=$(make_repo)
  { read -r BASE; read -r HEAD; } <<EOS
$(two_commits "$REPO")
EOS
  green_evidence "$REPO"
}

test_critical_package_passes_when_every_task_is_reviewed_after_its_last_change() {
  critical_range
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' 'Task 1: complete' \
    'Task 2: in-progress critical' 'Task 2: implemented' 'Task 2: reviewed by critical-reviewer' 'Task 2: fixing round 1' 'Task 2: reviewed by critical-reviewer' 'Task 2: complete'
  [ -f "$(critical_package "$REPO" "$BASE" "$HEAD")" ]
}

test_critical_package_refuses_a_task_never_reviewed() {
  critical_range
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' 'Task 1: complete' 'Task 2: in-progress critical' 'Task 2: implemented'
  local out rc=0
  out=$(critical_package "$REPO" "$BASE" "$HEAD" 2>&1) || rc=$?
  assert_eq 65 "$rc" "exit code"
  cli=$(cd -P "$SANDBOX/fp/bin" && pwd)/overdrive
  assert_line "$out" "overdrive: no critical review after the last change: task 2 has none; for each, run $cli review-package --base <task base> --head HEAD --brief <brief> --lane critical, then dispatch overdrive:critical-reviewer with \"Task <N>\" in its description (the guard records the review when it is dispatched); or, if this run was abandoned, $cli ledger add 'Run: closed — <reason>'"
  [ ! -e "$REPO/.overdrive/run/reviews" ] || [ -z "$(ls "$REPO/.overdrive/run/reviews")" ]
}

test_critical_package_refuses_a_fix_round_without_a_new_review() {
  critical_range
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' 'Task 1: fixing round 1' \
    'Task 2: in-progress critical' 'Task 2: implemented' 'Task 2: reviewed by critical-reviewer' 'Task 2: complete'
  local out rc=0
  out=$(critical_package "$REPO" "$BASE" "$HEAD" 2>&1) || rc=$?
  assert_eq 65 "$rc" "exit code"
  cli=$(cd -P "$SANDBOX/fp/bin" && pwd)/overdrive
  assert_line "$out" "overdrive: no critical review after the last change: task 1 has none; for each, run $cli review-package --base <task base> --head HEAD --brief <brief> --lane critical, then dispatch overdrive:critical-reviewer with \"Task <N>\" in its description (the guard records the review when it is dispatched); or, if this run was abandoned, $cli ledger add 'Run: closed — <reason>'"
  # Re-reviewing after the fix lets it through.
  (cd "$REPO" && od ledger _record-review 1) > /dev/null
  [ -f "$(critical_package "$REPO" "$BASE" "$HEAD")" ]
}

test_critical_package_names_every_uncovered_task() {
  critical_range
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 2: in-progress critical'
  local out rc=0
  out=$(critical_package "$REPO" "$BASE" "$HEAD" 2>&1) || rc=$?
  assert_eq 65 "$rc" "exit code"
  case $out in *"tasks 1, 2 have none"*) ;; *) fail "tasks not named: $out" ;; esac
}

test_critical_package_ignores_tasks_not_started() {
  critical_range
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' 'Task 2: pending'
  [ -f "$(critical_package "$REPO" "$BASE" "$HEAD")" ]
}

test_per_task_critical_package_is_not_gated() {
  critical_range
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented'
  [ -f "$(cd "$REPO" && od review-package --base "$BASE" --head "$HEAD" --lane critical)" ]
}

test_standard_package_ignores_the_per_task_gate() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  green_evidence "$repo"
  task_ledger "$repo" 'Task 1: implemented' 'Task 2: implemented'
  [ -f "$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green)" ]
}

test_critical_package_without_a_ledger_keeps_its_behavior() {
  critical_range
  [ -f "$(critical_package "$REPO" "$BASE" "$HEAD")" ]
  # A pointer to a ledger that is gone is no ledger either.
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented'
  rm -f "$(cd "$REPO" && od ledger path)"
  [ -f "$(critical_package "$REPO" "$BASE" "$HEAD")" ]
}

test_critical_package_ignores_a_ledger_bound_to_another_branch() {
  critical_range
  git -C "$REPO" checkout -q -b feat-a
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented'
  git -C "$REPO" checkout -q -b feat-b
  [ -f "$(critical_package "$REPO" "$BASE" "$HEAD")" ]
  git -C "$REPO" checkout -q feat-a
  local rc=0
  critical_package "$REPO" "$BASE" "$HEAD" >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
}

test_critical_package_ignores_standard_tasks_of_a_mixed_slice() {
  critical_range
  task_ledger "$REPO" 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' \
    'Task 2: in-progress' 'Task 2: implemented'
  [ -f "$(critical_package "$REPO" "$BASE" "$HEAD")" ]
}
