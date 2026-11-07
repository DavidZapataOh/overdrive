#!/usr/bin/env bash
# Tests for the scripts shipped with the skill-evaluation skill.

root=$(dirname "$(dirname "$RUNNER")")
scripts=$root/plugins/overdrive/skills/skill-evaluation/scripts

new_case() { bash "$scripts/new-pressure-case" "$@"; }
in_acme() { (cd acme && new_case "$@"); }

# plugin_at DIR [PLUGIN_JSON]: a minimal plugin directory.
plugin_at() {
  local json=${2-}
  [ -n "$json" ] || json='{"name": "acme"}'
  mkdir -p "$1/.claude-plugin" "$1/skills"
  printf '%s\n' "$json" > "$1/.claude-plugin/plugin.json"
}

test_new_pressure_case_scaffolds_scenario_and_case_in_a_marketplace_repo() {
  repo=$(make_repo)
  plugin_at "$repo/plugins/acme"
  mkdir -p "$repo/plugins/acme/evals/_lib"
  cp "$root/plugins/overdrive/evals/_lib/fixtures.sh" "$repo/plugins/acme/evals/_lib/"
  out=$(cd "$repo" && new_case commit-messages rushed-release)
  case_dir=$repo/plugins/acme/evals/commit-messages/pressure/rushed-release
  assert_line "$out" "$repo/tests/pressure/commit-messages/rushed-release/scenario.md"
  assert_line "$out" "$case_dir/prompt.md"
  assert_file_contains "$repo/tests/pressure/commit-messages/rushed-release/scenario.md" '^## Compliant choice$'
  assert_file_contains "$case_dir/prompt.md" '^tags: \[commit-messages-pressure\]$'
  assert_file_contains "$case_dir/prompt.md" 'What do you do\?$'
  assert_file_contains "$case_dir/case.yaml" '^name: rushed-release$'
  assert_file_contains "$case_dir/case.yaml" '^  scaffold_script: scaffold\.sh$'
  assert_file_contains "$case_dir/graders/compliant.md" '^type: llm$'
  assert_file_contains "$case_dir/scaffold.sh" '_lib/fixtures\.sh'
  [ -x "$case_dir/scaffold.sh" ] || { echo "scaffold.sh is not executable" >&2; return 1; }
}

test_scaffold_from_the_fixture_library_builds_a_repository() {
  repo=$(make_repo)
  plugin_at "$repo/plugins/acme"
  mkdir -p "$repo/plugins/acme/evals/_lib"
  cp "$root/plugins/overdrive/evals/_lib/fixtures.sh" "$repo/plugins/acme/evals/_lib/"
  (cd "$repo" && new_case commit-messages rushed-release > /dev/null)
  mkdir ws
  (cd ws && bash "$repo/plugins/acme/evals/commit-messages/pressure/rushed-release/scaffold.sh")
  assert_eq "1" "$(git -C ws rev-list --count HEAD)"
}

test_new_pressure_case_without_fixture_library_writes_a_plain_git_scaffold() {
  plugin_at acme
  (cd acme && new_case lint-fix friday-deploy > /dev/null)
  scaffold=acme/evals/lint-fix/pressure/friday-deploy/scaffold.sh
  assert_exit 1 grep -q '_lib/fixtures' "$scaffold"
  mkdir ws
  (cd ws && bash "../$scaffold")
  assert_eq "1" "$(git -C ws rev-list --count HEAD)"
  # Outside a git repository the scenario lives next to the plugin.
  [ -f acme/tests/pressure/lint-fix/friday-deploy/scenario.md ] || { echo "scenario.md missing" >&2; return 1; }
}

test_new_pressure_case_honors_a_custom_eval_directory() {
  plugin_at acme '{"name": "acme", "experimental": {"evals": "quality/evals"}}'
  (cd acme && new_case lint-fix friday-deploy > /dev/null)
  [ -f acme/quality/evals/lint-fix/pressure/friday-deploy/prompt.md ] || { echo "case not under quality/evals" >&2; return 1; }
}

test_new_pressure_case_takes_an_explicit_plugin_directory() {
  plugin_at one/a
  plugin_at two/b
  assert_exit 1 new_case lint-fix friday-deploy
  new_case lint-fix friday-deploy --plugin two/b > /dev/null
  [ -f two/b/evals/lint-fix/pressure/friday-deploy/case.yaml ] || { echo "case not under --plugin" >&2; return 1; }
}

test_new_pressure_case_never_overwrites() {
  plugin_at acme
  (cd acme && new_case lint-fix friday-deploy > /dev/null)
  echo 'edited' > acme/evals/lint-fix/pressure/friday-deploy/prompt.md
  assert_exit 1 in_acme lint-fix friday-deploy
  assert_eq "edited" "$(cat acme/evals/lint-fix/pressure/friday-deploy/prompt.md)"
}

test_new_pressure_case_rejects_names_that_are_not_kebab_case() {
  plugin_at acme
  assert_exit 64 in_acme Lint_Fix friday
  assert_exit 64 in_acme lint-fix ../escape
  assert_exit 64 in_acme lint-fix
  [ ! -e acme/evals ] || { echo "a rejected call wrote files" >&2; return 1; }
}

test_shipped_split_trigger_set_runs_on_its_own() {
  mkdir -p alone set/tdd-trigger-plain set/tdd-trigger-bugfix
  cp "$scripts/split-trigger-set" alone/
  printf -- '---\ntags: [tdd-trigger]\n---\nFix it.\n' > set/tdd-trigger-plain/prompt.md
  printf -- '---\nmax_turns: 3\n---\nFix it.\n' > set/tdd-trigger-bugfix/prompt.md
  bash alone/split-trigger-set set
  assert_file_contains set/tdd-trigger-plain/prompt.md '^tags: \[tdd-trigger, train\]$'
  assert_file_contains set/tdd-trigger-bugfix/prompt.md '^tags: \[validation\]$'
}
