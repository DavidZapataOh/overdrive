#!/usr/bin/env bash
# shellcheck disable=SC2016 # single quotes are deliberate: the text is evaluated or matched later
# Tests for tools/evals/summarize.sh.

# The native Windows jq writes CRLF unless told otherwise (-b); elsewhere the flag does nothing.
jq() { command jq -b "$@"; }

root=$(dirname "$(dirname "$RUNNER")")
tool() { bash "$root/tools/evals/summarize.sh" "$@"; }
recorded=$root/tests/evals/fixtures/aggregate-result.recorded.json

has() {
  if ! printf '%s\n' "$out" | grep -qF -- "$1"; then
    printf 'missing line: %s\n--- output ---\n%s\n' "$1" "$out" >&2
    return 1
  fi
}

# trigger_case NAME KIND FIRED RUNS: a trigger case where the skill fired in FIRED of RUNS runs.
# KIND is positive (grader passes when the skill fires) or negative (max: 0, passes when it does not).
trigger_case() {
  jq -n --arg name "$1" --arg kind "$2" --argjson fired "$3" --argjson runs "$4" '
    ($kind == "negative") as $neg
    | { name: $name, dir: ("evals/tdd/trigger/" + $name),
        graders: [ { name: "fired", type: "tool_used",
                     config: ({ tool: "Skill" } + (if $neg then { min: 0, max: 0, arm: "both" } else {} end)) } ],
        arms: { with: [ range(0; $runs) | . as $i | ($i < $fired) as $f
                | { score: (if $f != $neg then 1 else 0 end), error: null, costUsd: 0.01, judgeCostUsd: 0,
                    graders: [ { name: "fired", passed: ($f != $neg), scored: true } ] } ],
                without: [] } }
    | .aggregates = { score: ([.arms.with[].score] | add / length) }'
}

# behavior_case NAME WITH WITHOUT
behavior_case() {
  jq -n --arg name "$1" --argjson w "$2" --argjson wo "$3" '
    { name: $name, dir: ("evals/tdd/behavior/" + $name), graders: [],
      arms: { with: [ { score: $w, error: null, costUsd: 0.5, judgeCostUsd: 0.1, graders: [] } ],
              without: [ { score: $wo, error: null, costUsd: 0.4, judgeCostUsd: 0.1, graders: [] } ] },
      aggregates: { score: $w, scoreWithout: $wo, delta: ($w - $wo) } }'
}

# doc CASE_FILES...: wraps cases in an aggregate document.
doc() {
  jq -s '{ schemaVersion: 1, claudeVersion: "2.1.319", startedAt: "2026-11-07T02:18:56.787Z",
           durationSeconds: 90, costUsd: 3.5, partial: false,
           suite: { modelOverride: "claude-opus-5-5" },
           cases: ., aggregates: { casesTotal: (. | length), casesPassed: (. | length), overallScore: 0.8, meanDelta: 0.1 } }' "$@"
}

test_summarize_trigger_accuracy() {
  # tdd-trigger-{plain,feature,refactor,typo} hash to train; {bugfix,new-api,a,f,g} to validation.
  {
    trigger_case tdd-trigger-plain positive 3 3 > c1
    trigger_case tdd-trigger-feature positive 2 3 > c2
    trigger_case tdd-trigger-refactor negative 0 3 > c3
    trigger_case tdd-trigger-typo negative 3 3 > c4
    trigger_case tdd-trigger-bugfix positive 3 3 > c5
    trigger_case tdd-trigger-new-api positive 1 3 > c6
    trigger_case tdd-trigger-a negative 0 3 > c7
    trigger_case tdd-trigger-f negative 1 3 > c8
    trigger_case tdd-trigger-g negative 2 3 > c9
  }
  doc c1 c2 c3 c4 c5 c6 c7 c8 c9 > suite.json
  out=$(tool --skill tdd suite.json)
  has 'Trigger accuracy (train): 3/4 (75%)'
  has 'Trigger accuracy (validation): 3/5 (60%), floor 90%: FAIL'
  has '| tdd-trigger-feature | trigger | 0.67 | n/a | n/a | 3 | $0.03 | positive: fired 2/3 |'
  has '| tdd-trigger-f | trigger | 0.67 | n/a | n/a | 3 | $0.03 | negative: fired 1/3 |'
}

test_summarize_trigger_accuracy_passes_at_the_floor() {
  trigger_case tdd-trigger-bugfix positive 3 3 > c1
  doc c1 > suite.json
  out=$(tool --skill tdd suite.json)
  has 'Trigger accuracy (validation): 1/1 (100%), floor 90%: PASS'
  has 'Trigger accuracy (train): none'
}

test_summarize_ignores_runs_that_errored_before_grading() {
  trigger_case tdd-trigger-bugfix positive 2 3 > c1
  jq '.arms.with[2] |= (.score = 0 | .error = "rate limited" | .graders = [])' c1 > c1b
  doc c1b > suite.json
  out=$(tool --skill tdd suite.json)
  has 'positive: fired 2/2'
  has 'Trigger accuracy (validation): 1/1 (100%), floor 90%: PASS'
}

test_summarize_reports_negative_delta() {
  behavior_case tdd-behavior-red-first 0.6 0.9 > c1
  behavior_case tdd-behavior-small-step 1 0.5 > c2
  doc c1 c2 > suite.json
  out=$(tool --skill tdd suite.json)
  has '| tdd-behavior-red-first | behavior | 0.60 | 0.90 | -0.30 | 1 | $1.10 | REGRESSION |'
  has '| tdd-behavior-small-step | behavior | 1.00 | 0.50 | +0.50 | 1 | $1.10 |  |'
  has 'Cases with negative delta: 1 (tdd-behavior-red-first)'
}

test_summarize_header_and_metadata() {
  behavior_case tdd-behavior-red-first 1 0.5 > c1
  doc c1 > suite.json
  out=$(tool --skill tdd --tier full --model claude-opus-5-5 --judge claude-sonnet-5-5 suite.json)
  has '# Eval results: tdd'
  has '- Date: 2026-11-07'
  has '- Claude Code: 2.1.319'
  has '- Tier: full'
  has '- Agent model: claude-opus-5-5'
  has '- Judge model: claude-sonnet-5-5'
  has '- Suite: score 0.80, mean delta +0.10, cases passed 1/1, cost $3.50, 90s'
  has 'Cases with negative delta: none'
  has 'Trigger accuracy (validation): none'
}

test_summarize_marks_partial_runs() {
  behavior_case tdd-behavior-red-first 1 0.5 > c1
  doc c1 | jq '.partial = true | .partialReason = "cost_ceiling"' > suite.json
  out=$(tool --skill tdd suite.json)
  has '- Partial: yes (cost_ceiling), not comparable with complete runs'
}

test_summarize_reads_a_recorded_document() {
  out=$(tool --skill spike "$recorded")
  has '- Claude Code: 2.1.319'
  has '| spike-probe | behavior | 1.00 | 0.67 | +0.33 | 1 | $0.0032 |  |'
  has 'Cases with negative delta: none'
}

test_summarize_single_arm_documents() {
  behavior_case tdd-behavior-red-first 1 0.5 > c1
  jq '.arms.without = [] | del(.aggregates.delta, .aggregates.scoreWithout)' c1 > c1b
  doc c1b > suite.json
  out=$(tool --skill tdd suite.json)
  has '| tdd-behavior-red-first | behavior | 1.00 | n/a | n/a | 1 | $0.60 |  |'
}

test_summarize_usage_errors() {
  assert_exit 64 tool
  assert_exit 1 tool missing.json
  echo '{"schemaVersion": 2}' > v2.json
  assert_exit 1 tool v2.json
}
