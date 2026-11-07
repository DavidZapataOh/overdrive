#!/usr/bin/env bash
# Tests for tools/evals/changed-skills.sh.

root=$(dirname "$(dirname "$RUNNER")")
tool() { bash "$root/tools/evals/changed-skills.sh" "$@"; }

# plugin_repo: a repository with eval cases for tdd and debugging, none for planning.
plugin_repo() {
  repo=$(make_repo)
  commit_file "$repo" plugins/overdrive/evals/tdd/trigger/tdd-trigger-a/prompt.md 'x'
  commit_file "$repo" plugins/overdrive/evals/debugging/behavior/debugging-behavior-a/case.yaml 'x'
  commit_file "$repo" plugins/overdrive/evals/_lib/fixtures.sh 'x'
  commit_file "$repo" plugins/overdrive/evals/planning/README 'no cases yet'
  commit_file "$repo" plugins/overdrive/skills/tdd/SKILL.md 'x'
  commit_file "$repo" plugins/overdrive/skills/planning/SKILL.md 'x'
  commit_file "$repo" README.md 'x'
  base=$(git -C "$repo" rev-parse HEAD)
}

test_all_lists_skills_that_have_cases() {
  plugin_repo
  assert_eq "debugging
tdd" "$(tool --root "$repo")"
}

test_changed_skill_selects_only_that_skill() {
  plugin_repo
  commit_file "$repo" plugins/overdrive/skills/tdd/references/red-green.md 'y'
  assert_eq "tdd" "$(tool --root "$repo" "$base" HEAD)"
}

test_changed_eval_case_selects_its_skill() {
  plugin_repo
  commit_file "$repo" plugins/overdrive/evals/debugging/behavior/debugging-behavior-b/prompt.md 'y'
  assert_eq "debugging" "$(tool --root "$repo" "$base" HEAD)"
}

test_skill_without_cases_is_not_selected() {
  plugin_repo
  commit_file "$repo" plugins/overdrive/skills/planning/SKILL.md 'changed'
  assert_eq "" "$(tool --root "$repo" "$base" HEAD)"
}

test_shared_plugin_code_selects_every_skill_with_cases() {
  plugin_repo
  commit_file "$repo" plugins/overdrive/hooks/session-start 'y'
  assert_eq "debugging
tdd" "$(tool --root "$repo" "$base" HEAD)"
}

test_shared_fixtures_and_eval_tools_select_every_skill() {
  plugin_repo
  commit_file "$repo" plugins/overdrive/evals/_lib/fixtures.sh 'y'
  assert_eq "debugging
tdd" "$(tool --root "$repo" "$base" HEAD)"
  commit_file "$repo" tools/evals/summarize.sh 'y'
  assert_eq "debugging
tdd" "$(tool --root "$repo" "$base" HEAD)"
}

test_unrelated_changes_select_nothing() {
  plugin_repo
  commit_file "$repo" docs/lanes.md 'y'
  commit_file "$repo" tests/risk/x 'y'
  assert_eq "" "$(tool --root "$repo" "$base" HEAD)"
}

test_results_directory_is_not_a_skill() {
  plugin_repo
  commit_file "$repo" plugins/overdrive/evals/results/tdd-full.json '{}'
  assert_eq "debugging
tdd" "$(tool --root "$repo")"
}

test_unreadable_range_fails() {
  plugin_repo
  assert_exit 1 tool --root "$repo" deadbeef HEAD
}
