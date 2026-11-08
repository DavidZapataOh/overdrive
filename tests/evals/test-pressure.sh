#!/usr/bin/env bash
# Tests for tools/evals/pressure.sh.

root=$(dirname "$(dirname "$RUNNER")")

project() {
  mkdir -p repo/plugins/overdrive/evals/_lib repo/plugins/overdrive/evals/tdd/pressure/tdd-skip-tests fakebin
  echo '# fixtures' > repo/plugins/overdrive/evals/_lib/fixtures.sh
  echo 'Ship it now.' > repo/plugins/overdrive/evals/tdd/pressure/tdd-skip-tests/prompt.md
  cp "$root/tests/evals/fake-claude" fakebin/claude
  export XDG_CACHE_HOME=$PWD/cache FAKE_ENV=$PWD/env.log
  export FAKE_LOG=$PWD/calls.log FAKE_SNAPSHOT=$PWD/snapshot.log
  : > "$FAKE_LOG"
  : > "$FAKE_SNAPSHOT"
  PATH=$PWD/fakebin:$PATH
}

pressure() { bash "$root/tools/evals/pressure.sh" "$@" --root "$PWD/repo"; }

runs=repo/tests/pressure/tdd/skip-tests/runs

# One run as written for reading: the assistant text blocks, then the final message.
run_file() {
  printf '## Assistant text 1\n\nLast assistant text %s\n\n## Final message\n\nFinal message %s' "$1" "$1"
}

test_with_arm_writes_each_run_and_removes_kept_sandboxes() {
  project
  FAKE_KEPT=3 pressure tdd skip-tests --arm with --runs 3 > /dev/null
  assert_eq "$(run_file 1)" "$(cat $runs/with-1.md)"
  assert_eq "$(run_file 2)" "$(cat $runs/with-2.md)"
  assert_eq "$(run_file 3)" "$(cat $runs/with-3.md)"
  assert_eq "0" "$(find "$TMPDIR" -maxdepth 1 -name 'claude-eval-*' | wc -l | tr -d ' ')"
  . "$root/tools/evals/models.env"
  case "$(cat "$FAKE_LOG")" in
    *"plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 3 --keep-temp --max-cost-usd 15 --model $OD_EVAL_MODEL_MAIN --case tdd-skip-tests --tag tdd-pressure --json "*) ;;
    *) printf 'unexpected call: %s\n' "$(cat "$FAKE_LOG")" >&2; return 1 ;;
  esac
}

test_default_is_five_runs() {
  project
  FAKE_KEPT=5 pressure tdd skip-tests --arm with > /dev/null
  assert_file_contains "$FAKE_LOG" ' --runs 5 '
}

test_without_arm_runs_the_scenario_under_an_empty_plugin() {
  project
  FAKE_KEPT=2 pressure tdd skip-tests --arm without --runs 2 > /dev/null
  assert_eq "$(run_file 1)" "$(cat $runs/without-1.md)"
  assert_eq "$(run_file 2)" "$(cat $runs/without-2.md)"
  # The scaffold-relative library and only the requested scenario travel with the copy.
  assert_line "$(cat "$FAKE_SNAPSHOT")" "./.claude-plugin/plugin.json"
  assert_line "$(cat "$FAKE_SNAPSHOT")" "./evals/_lib/fixtures.sh"
  assert_line "$(cat "$FAKE_SNAPSHOT")" "./evals/tdd/pressure/tdd-skip-tests/prompt.md"
  assert_no_line "$(cat "$FAKE_SNAPSHOT")" 'skills/|hooks/|agents/'
  assert_no_line "$(cat "$FAKE_LOG")" 'plugins/overdrive '
  assert_file_contains "$FAKE_LOG" ' --ablation none '
}

test_a_trace_without_a_result_record_falls_back_to_the_last_assistant_text() {
  project
  FAKE_NO_RESULT=1 FAKE_KEPT=1 pressure tdd skip-tests --arm with --runs 1 > /dev/null
  assert_eq "## Assistant text 1

Last assistant text 1

## Final message

Last assistant text 1" "$(cat $runs/with-1.md)"
}

test_every_assistant_text_comes_before_the_marked_final_message() {
  project
  FAKE_EARLIER=1 FAKE_KEPT=1 pressure tdd skip-tests --arm with --runs 1 > /dev/null
  assert_eq "## Assistant text 1

Earlier text 1

## Assistant text 2

Last assistant text 1

## Final message

Final message 1" "$(cat $runs/with-1.md)"
}

test_runs_directory_is_gitignored() {
  git -C "$root" check-ignore -q tests/pressure/tdd/skip-tests/runs/with-1.md
}

test_usage_errors() {
  project
  assert_exit 64 pressure
  assert_exit 64 pressure tdd skip-tests
  assert_exit 64 pressure tdd skip-tests --arm both
  assert_exit 64 pressure tdd skip-tests --arm with --runs 0
  assert_exit 1 pressure tdd missing --arm with
  assert_eq "0" "$(wc -l < "$FAKE_LOG" | tr -d ' ')"
}

test_no_matching_case_is_an_error() {
  project
  echo '{"schemaVersion":1,"cases":[]}' > empty.json
  FAKE_RESULT=$PWD/empty.json assert_exit 1 pressure tdd skip-tests --arm with
  assert_eq "0" "$(find repo/tests/pressure -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
}

test_unreadable_result_is_an_error() {
  project
  echo 'not json' > bad.json
  FAKE_RESULT=$PWD/bad.json assert_exit 1 pressure tdd skip-tests --arm with
}

test_case_with_no_runs_is_an_error() {
  project
  echo '{"schemaVersion":1,"cases":[{"name":"x","arms":{"with":[],"without":[]}}]}' > none.json
  FAKE_RESULT=$PWD/none.json assert_exit 1 pressure tdd skip-tests --arm with
}

test_an_errored_run_fails_the_command_but_keeps_the_evidence() {
  project
  FAKE_RUN_ERROR='timed out after 300s' FAKE_KEPT=2 assert_exit 1 pressure tdd skip-tests --arm with --runs 2
  assert_file_contains $runs/with-1.md '^RUN ERROR: timed out after 300s$'
}

test_fewer_recorded_runs_than_requested_fail_the_command() {
  project
  FAKE_KEPT=2 assert_exit 1 pressure tdd skip-tests --arm with --runs 3
  assert_eq "$(run_file 2)" "$(cat $runs/with-2.md)"
}

test_reports_the_run_cost_and_duration() {
  project
  out=$(FAKE_COST=1.23456 FAKE_KEPT=2 pressure tdd skip-tests --arm with --runs 2)
  assert_line "$out" "pressure: cost \$1.23, 1 s"
}

test_grants_come_from_the_skills_allow_tools_file() {
  project
  printf '# what the cases need\nWrite\n\nBash(git *)\r\n' > repo/plugins/overdrive/evals/tdd/allow-tools
  FAKE_KEPT=1 pressure tdd skip-tests --arm with --runs 1 > /dev/null
  grep -qF -- ' --tag tdd-pressure --allow-tools Write Bash(git *) --json ' "$FAKE_LOG"
}

test_no_grants_file_passes_no_allow_tools() {
  project
  FAKE_KEPT=1 pressure tdd skip-tests --arm with --runs 1 > /dev/null
  ! grep -q -- '--allow-tools' "$FAKE_LOG"
}

test_temp_tree_moves_out_of_tmp_on_linux() {
  [ "$(uname -s)" = Linux ] || return 0
  project
  TMPDIR=/tmp FAKE_KEPT=1 pressure tdd skip-tests --arm with --runs 1 > /dev/null
  assert_file_contains "$FAKE_ENV" "^TMPDIR=$XDG_CACHE_HOME/overdrive-evals/tmp\$"
}

test_path_drops_entries_that_are_not_readable_directories() {
  project
  PATH=$PATH:$PWD/missing FAKE_KEPT=1 pressure tdd skip-tests --arm with --runs 1 > /dev/null
  ! grep -q "$PWD/missing" "$FAKE_ENV"
}
