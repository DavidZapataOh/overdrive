#!/usr/bin/env bash
# Tests for tools/evals/run-suite.sh and tools/evals/models.env.

# The native Windows jq writes CRLF unless told otherwise (-b); elsewhere the flag does nothing.
jq() { command jq -b "$@"; }

root=$(dirname "$(dirname "$RUNNER")")
recorded=$root/tests/evals/fixtures/aggregate-result.recorded.json

# project: a repository root with a plugin that has eval cases for the tdd skill.
project() {
  mkdir -p repo/plugins/overdrive/evals/tdd/trigger repo/plugins/overdrive/evals/tdd/pressure/skip-tests \
    repo/plugins/overdrive/evals/tdd/pressure/rush-fix fakebin
  cp "$root/tests/evals/fake-claude" fakebin/claude
  export FAKE_LOG=$PWD/calls.log FAKE_SNAPSHOT=$PWD/snapshot.log FAKE_RESULT=$recorded
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
  out=$(suite tdd --tier smoke)
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

test_cost_ceiling_can_be_overridden() {
  project
  suite tdd --tier full --max-cost-usd 4 > /dev/null
  assert_call_has "--max-cost-usd 4"
}

test_pressure_runs_every_scenario_five_times_with_the_plugin() {
  project
  FAKE_KEPT=1 suite tdd --tier pressure > /dev/null
  assert_eq "2" "$(wc -l < "$FAKE_LOG" | tr -d ' ')"
  assert_call_has "--runs 5 --keep-temp"
  assert_file_contains "$FAKE_LOG" '--case rush-fix '
  assert_file_contains "$FAKE_LOG" '--case skip-tests '
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

test_usage_errors() {
  project
  assert_exit 64 suite
  assert_exit 64 suite tdd
  assert_exit 64 suite tdd --tier nightly
  assert_exit 64 suite tdd --tier full --model gpt
  assert_exit 1 suite unknown --tier smoke
  assert_eq "0" "$(wc -l < "$FAKE_LOG" | tr -d ' ')"
}
