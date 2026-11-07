#!/usr/bin/env bash
# Tests for overdrive overlap and the plan parser it shares with brief.

fixtures() { printf '%s\n' "$(dirname "$RUNNER")/brief/fixtures"; }
od() { "$BASH" "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" "$@"; }

test_overlap_reports_shared_file() {
  local out
  out=$(od overlap --plan "$(fixtures)/plan.md" --tasks 1,2,7)
  assert_eq "$(printf '%s\n' 'conflict 1 2 docs/a.md' 'independent 7')" "$out"
  out=$(od overlap --plan "$(fixtures)/plan.md" --tasks 1,7)
  assert_eq 'independent 1,7' "$out"
}

test_overlap_strips_line_ranges() {
  local out
  out=$(od overlap --plan "$(fixtures)/plan.md" --tasks 2,4)
  assert_eq "$(printf '%s\n' 'conflict 2 4 plugins/x/lib/common.sh' 'independent none')" "$out"
}

test_overlap_directory_contains_file() {
  local out
  out=$(od overlap --plan "$(fixtures)/plan.md" --tasks 3,5,1)
  assert_eq "$(printf '%s\n' 'conflict 3 5 src/app/' 'independent 1')" "$out"
}

test_overlap_task_without_files_is_not_independent() {
  local out
  out=$(od overlap --plan "$(fixtures)/plan.md" --tasks 6,7)
  assert_eq "$(printf '%s\n' 'note task 6 lists no files' 'independent 7')" "$out"
}

test_overlap_ignores_fenced_and_annotation_paths() {
  local out
  out=$(od overlap --plan "$(fixtures)/tdd-plan.md" --tasks 1,2)
  assert_eq "$(printf '%s\n' 'conflict 1 2 turbo.json' 'independent none')" "$out"
  out=$(od overlap --plan "$(fixtures)/plan.md" --tasks 1,3)
  assert_eq 'independent 1,3' "$out"
}

test_overlap_bad_input() {
  assert_exit 65 od overlap --plan "$(fixtures)/plan.md" --tasks 1,9
  assert_exit 64 od overlap --plan "$(fixtures)/plan.md"
  assert_exit 64 od overlap --plan "$(fixtures)/plan.md" --tasks 'a;b'
  assert_exit 66 od overlap --plan "$PWD/missing.md" --tasks 1,2
}

test_plan_task_files() {
  . "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/lib/plan.sh"
  assert_eq "$(printf '%s\n' 'plugins/x/libexec/a' 'docs/a.md' 'tests/a/test-a.sh')" "$(plan_task_files "$(fixtures)/plan.md" 1)"
  assert_eq "$(printf '%s\n' 'src/(marketing)/page.tsx' 'src/app/')" "$(plan_task_files "$(fixtures)/plan.md" 3)"
  assert_eq "$(printf '%s\n' 'vitest.config.ts' 'packages/testing/src/env.ts' 'pnpm-workspace.yaml' 'turbo.json' 'package.json' 'packages/testing/src/env.test.ts')" \
    "$(plan_task_files "$(fixtures)/tdd-plan.md" 1)"
  assert_exit 1 plan_task "$(fixtures)/plan.md" 9
  assert_exit 1 plan_global_constraints "$(fixtures)/../test-brief.sh"
}
