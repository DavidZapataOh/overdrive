#!/usr/bin/env bash
# Tests for tools/evals/run-suite.sh and tools/evals/models.env.

# The native Windows jq writes CRLF unless told otherwise (-b); elsewhere the flag does nothing.
jq() { command jq -b "$@"; }

root=$(dirname "$(dirname "$RUNNER")")
recorded=$root/tests/evals/fixtures/aggregate-result.recorded.json

# project: a repository root with a plugin that has eval cases for the tdd skill.
project() {
  mkdir -p repo/plugins/overdrive/evals/tdd/trigger repo/plugins/overdrive/evals/tdd/pressure/tdd-skip-tests \
    repo/plugins/overdrive/evals/tdd/pressure/tdd-rush-fix fakebin
  cp "$root/tests/evals/fake-claude" fakebin/claude
  # The recorded document has one run per arm; a full suite asks for three.
  jq '.suite.ablation = "with-without" | .cases[].arms |= map_values(. + . + .)' "$recorded" > full.json
  export XDG_CACHE_HOME=$PWD/cache FAKE_ENV=$PWD/env.log
  export FAKE_LOG=$PWD/calls.log FAKE_SNAPSHOT=$PWD/snapshot.log FAKE_RESULT=$PWD/full.json
  : > "$FAKE_LOG"
  PATH=$PWD/fakebin:$PATH
}

suite() { bash "$root/tools/evals/run-suite.sh" "$@" --root "$PWD/repo"; }

# 1 call with each argument present, in order, as a space-delimited fragment.
assert_call_has() {
  case " $(cat "$FAKE_LOG") " in
    *" $1 "*) ;;
    *) printf 'no call contains: %s\n%s\n' "$1" "$(cat "$FAKE_LOG")" >&2; return 1 ;;
  esac
}

test_models_env_pins_full_model_ids() {
  . "$root/tools/evals/models.env"
  case $OD_EVAL_MODEL_MAIN in claude-opus-[0-9]*) ;; *) echo "main: $OD_EVAL_MODEL_MAIN" >&2; return 1 ;; esac
  case $OD_EVAL_MODEL_SONNET in claude-sonnet-[0-9]*) ;; *) echo "sonnet: $OD_EVAL_MODEL_SONNET" >&2; return 1 ;; esac
  case $OD_EVAL_JUDGE in claude-[a-z]*-[0-9]*) ;; *) echo "judge: $OD_EVAL_JUDGE" >&2; return 1 ;; esac
}

test_smoke_runs_one_arm_one_run_with_free_graders_only() {
  project
  out=$(FAKE_RESULT=$recorded suite tdd --tier smoke)
  assert_call_has "plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 1 --max-cost-usd 2 --model claude-opus-5-5 --json $PWD/repo/plugins/overdrive/evals/results/tdd-smoke.json --tag tdd-smoke"
  assert_eq "1" "$(wc -l < "$FAKE_LOG" | tr -d ' ')"
  case $out in *'# Eval results: tdd'*) ;; *) echo "no summary printed" >&2; return 1 ;; esac
  [ ! -e repo/plugins/overdrive/evals/tdd/RESULTS.md ] || { echo "smoke must not write RESULTS.md" >&2; return 1; }
}

test_full_compares_with_and_without_and_pins_models() {
  project
  suite tdd --tier full > /dev/null
  . "$root/tools/evals/models.env"
  assert_call_has "plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation with-without --runs 3 --threshold 0.9 --max-cost-usd 25 --model $OD_EVAL_MODEL_MAIN --judge-model $OD_EVAL_JUDGE --json $PWD/repo/plugins/overdrive/evals/results/tdd-full.json --tag tdd-trigger tdd-behavior"
  results=repo/plugins/overdrive/evals/tdd/RESULTS.md
  assert_file_contains "$results" '^# Eval results: tdd$'
  assert_file_contains "$results" "^- Agent model: $OD_EVAL_MODEL_MAIN\$"
  assert_file_contains "$results" "^- Judge model: $OD_EVAL_JUDGE\$"
  assert_file_contains "$results" '^- Tier: full$'
}

test_full_model_sonnet_selects_the_sonnet_id() {
  project
  suite tdd --tier full --model sonnet > /dev/null
  . "$root/tools/evals/models.env"
  assert_call_has "--model $OD_EVAL_MODEL_SONNET"
}

test_allow_tools_are_passed_last() {
  project
  suite tdd --tier full --allow-tools Write Edit > /dev/null
  case "$(cat "$FAKE_LOG")" in
    *'--tag tdd-trigger tdd-behavior --allow-tools Write Edit '*) ;;
    *) printf 'allow-tools not last: %s\n' "$(cat "$FAKE_LOG")" >&2; return 1 ;;
  esac
}

test_concurrency_is_passed_through() {
  project
  suite tdd --tier full --concurrency 4 > /dev/null
  assert_call_has "--concurrency 4"
}

test_cost_ceiling_can_be_overridden() {
  project
  suite tdd --tier full --max-cost-usd 4 > /dev/null
  assert_call_has "--max-cost-usd 4"
}

test_pressure_runs_every_scenario_five_times_with_the_plugin() {
  project
  FAKE_KEPT=5 suite tdd --tier pressure > /dev/null
  assert_eq "2" "$(wc -l < "$FAKE_LOG" | tr -d ' ')"
  assert_call_has "--runs 5 --keep-temp"
  assert_file_contains "$FAKE_LOG" '--case tdd-rush-fix '
  assert_file_contains "$FAKE_LOG" '--case tdd-skip-tests '
  [ -d repo/tests/pressure/tdd/rush-fix/runs ] || { echo "runs not under the scenario name" >&2; return 1; }
}

test_case_glob_is_passed_to_the_cli() {
  project
  suite tdd --tier smoke --case 'tdd-behavior-*' > /dev/null
  case "$(cat "$FAKE_LOG")" in
    *' --tag tdd-smoke --case tdd-behavior-* '* | *' --case tdd-behavior-* '*) ;;
    *) printf 'case glob not passed: %s\n' "$(cat "$FAKE_LOG")" >&2; return 1 ;;
  esac
}

test_a_case_glob_matching_no_case_fails_clearly() {
  project
  jq '.cases = []' "$recorded" > none.json
  rc=0
  err=$(FAKE_RESULT=$PWD/none.json suite tdd --tier smoke --case 'tdd-nothing-*' 2>&1 > /dev/null) || rc=$?
  [ "$rc" -ne 0 ] || { echo "a glob matching no case must fail" >&2; return 1; }
  case $err in *'no eval case matches'*'tdd-nothing-*'*) ;; *) printf 'unclear message: %s\n' "$err" >&2; return 1 ;; esac
}

test_a_narrowed_full_run_does_not_write_results() {
  project
  suite tdd --tier full --case 'tdd-behavior-*' > /dev/null
  [ ! -e repo/plugins/overdrive/evals/tdd/RESULTS.md ] || { echo "a narrowed run must not write RESULTS.md" >&2; return 1; }
}

test_pressure_case_glob_runs_only_the_matching_scenarios() {
  project
  FAKE_KEPT=5 suite tdd --tier pressure --case 'tdd-rush-*' > /dev/null
  assert_eq "1" "$(wc -l < "$FAKE_LOG" | tr -d ' ')"
  assert_file_contains "$FAKE_LOG" '--case tdd-rush-fix '
  assert_exit 1 suite tdd --tier pressure --case 'tdd-nothing-*'
}

test_skill_grants_come_from_the_allow_tools_file() {
  project
  printf 'Write\n# shell for the test runner\n\nBash(npm test *)\n' > repo/plugins/overdrive/evals/tdd/allow-tools
  suite tdd --tier full > /dev/null
  case "$(cat "$FAKE_LOG")" in
    *'--allow-tools Write Bash(npm test *) '*) ;;
    *) printf 'grants not read from the file: %s\n' "$(cat "$FAKE_LOG")" >&2; return 1 ;;
  esac
}

test_command_line_grants_replace_the_allow_tools_file() {
  project
  printf 'Write\n' > repo/plugins/overdrive/evals/tdd/allow-tools
  suite tdd --tier smoke --allow-tools Edit > /dev/null
  case "$(cat "$FAKE_LOG")" in
    *'--allow-tools Edit '*) ;;
    *) printf 'unexpected grants: %s\n' "$(cat "$FAKE_LOG")" >&2; return 1 ;;
  esac
  assert_exit 1 grep -q -- '--allow-tools Write' "$FAKE_LOG"
}

test_failed_threshold_still_writes_results_and_propagates_the_status() {
  project
  FAKE_EXIT=1 assert_exit 1 suite tdd --tier full
  assert_file_contains repo/plugins/overdrive/evals/tdd/RESULTS.md '^# Eval results: tdd$'
}

test_partial_run_does_not_overwrite_results() {
  project
  mkdir -p repo/plugins/overdrive/evals/tdd
  echo kept > repo/plugins/overdrive/evals/tdd/RESULTS.md
  jq '.partial = true | .partialReason = "cost_ceiling"' "$recorded" > partial.json
  FAKE_RESULT=$PWD/partial.json FAKE_EXIT=2 assert_exit 2 suite tdd --tier full
  assert_eq "kept" "$(cat repo/plugins/overdrive/evals/tdd/RESULTS.md)"
}

test_e2e_runs_behavior_cases_with_the_plugin_only() {
  project
  mkdir -p repo/plugins/overdrive/evals/e2e/behavior
  out=$(FAKE_KEPT=3 suite e2e --tier e2e --model sonnet)
  . "$root/tools/evals/models.env"
  assert_call_has "plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 3 --keep-temp --max-cost-usd 30 --model $OD_EVAL_MODEL_SONNET --judge-model $OD_EVAL_JUDGE --json $PWD/repo/plugins/overdrive/evals/results/e2e-e2e.json --tag e2e-behavior"
  case $out in *'- Tier: e2e'*) ;; *) echo "no summary printed" >&2; return 1 ;; esac
  [ ! -e repo/plugins/overdrive/evals/e2e/RESULTS.md ] || { echo "e2e must not write RESULTS.md" >&2; return 1; }
}

test_e2e_runs_override_is_passed_and_other_tiers_reject_it() {
  project
  mkdir -p repo/plugins/overdrive/evals/e2e/behavior
  FAKE_KEPT=1 suite e2e --tier e2e --runs 1 > /dev/null
  assert_call_has "--ablation none --runs 1 --keep-temp --max-cost-usd 30"
  assert_exit 64 suite tdd --tier full --runs 2
  assert_exit 64 suite e2e --tier e2e --runs 0
  assert_exit 64 suite e2e --tier e2e --runs 00
}

test_usage_errors() {
  project
  assert_exit 64 suite
  assert_exit 64 suite tdd
  assert_exit 64 suite tdd --tier nightly
  assert_exit 64 suite tdd --tier full --model gpt
  assert_exit 64 suite tdd --tier full --concurrency many
  assert_exit 64 suite tdd --tier smoke --case
  assert_exit 64 suite tdd --tier smoke --case ''
  assert_exit 64 suite tdd --tier pressure --concurrency 2
  assert_exit 1 suite unknown --tier smoke
  assert_eq "0" "$(wc -l < "$FAKE_LOG" | tr -d ' ')"
}

test_only_the_summary_reaches_stdout() {
  project
  out=$(FAKE_RESULT=$recorded FAKE_STDOUT='progress noise' suite tdd --tier smoke 2>/dev/null)
  case $out in *noise*) echo "claude output leaked into stdout" >&2; return 1 ;; esac
  case $out in *'# Eval results: tdd'*) ;; *) echo "no summary" >&2; return 1 ;; esac
}

test_errored_runs_fail_the_run_even_when_claude_exits_zero() {
  project
  jq '.cases[0].arms.with[0].error = "timed out after 300s"' "$recorded" > errored.json
  FAKE_RESULT=$PWD/errored.json assert_exit 1 suite tdd --tier smoke
}

test_models_env_records_the_verified_claude_code_version() {
  . "$root/tools/evals/models.env"
  assert_eq "2.1.322" "$OD_EVAL_CLAUDE_VERSION"
}

test_a_broken_baseline_run_fails_the_suite() {
  project
  jq '.cases[0].arms.without[0].error = "rate limited"' full.json > broken.json
  FAKE_RESULT=$PWD/broken.json assert_exit 1 suite tdd --tier full
}

test_unrecorded_runs_fail_the_suite() {
  project
  # The recorded document holds one run per arm; a full suite asks for three.
  FAKE_RESULT=$recorded assert_exit 1 suite tdd --tier full
}

test_temp_tree_moves_out_of_tmp_on_linux() {
  [ "$(uname -s)" = Linux ] || return 0
  project
  TMPDIR=/tmp suite tdd --tier smoke > /dev/null
  assert_file_contains "$FAKE_ENV" "^TMPDIR=$XDG_CACHE_HOME/overdrive-evals/tmp\$"
  [ -d "$XDG_CACHE_HOME/overdrive-evals/tmp" ]
}

test_temp_tree_override_wins() {
  project
  OVERDRIVE_EVAL_TMPDIR=$PWD/custom suite tdd --tier smoke > /dev/null
  assert_file_contains "$FAKE_ENV" "^TMPDIR=$PWD/custom\$"
  [ -d custom ]
}

test_temp_tree_outside_tmp_is_kept() {
  [ "$(uname -s)" = Linux ] || return 0
  project
  elsewhere=$(mktemp -d "$HOME/od-test.XXXXXX") || return 1
  TMPDIR=$elsewhere suite tdd --tier smoke > /dev/null
  rc=0
  assert_file_contains "$FAKE_ENV" "^TMPDIR=$elsewhere\$" || rc=1
  rm -rf "$elsewhere"
  return "$rc"
}

test_path_drops_entries_that_are_not_readable_directories() {
  project
  mkdir -p locked ok
  chmod 000 locked
  PATH=$PATH:$PWD/locked:$PWD/missing:$PWD/ok suite tdd --tier smoke > /dev/null
  chmod 700 locked
  path=$(sed -n 's/^PATH=//p' "$FAKE_ENV")
  case ":$path:" in *":$PWD/missing:"*) echo "kept a missing entry" >&2; return 1 ;; esac
  case ":$path:" in *":$PWD/ok:"*) ;; *) echo "dropped a readable entry" >&2; return 1 ;; esac
  case ":$path:" in *":$PWD/fakebin:"*) ;; *) echo "dropped fakebin" >&2; return 1 ;; esac
  # chmod cannot make a directory unreadable for its owner on Windows, nor for root.
  case $OSTYPE in msys* | cygwin*) return 0 ;; esac
  [ "$(id -u)" = 0 ] || case ":$path:" in *":$PWD/locked:"*) echo "kept an unreadable entry" >&2; return 1 ;; esac
}

test_path_puts_the_stand_in_gh_first() {
  project
  suite tdd --tier smoke > /dev/null
  path=$(sed -n 's/^PATH=//p' "$FAKE_ENV")
  case $path in "$root/tools/evals/bin:"*) ;; *) echo "path: $path" >&2; return 1 ;; esac
}
