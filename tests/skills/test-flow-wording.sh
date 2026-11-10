#!/usr/bin/env bash
# The lane flows depend on instructions the model reads; these pin the lines that e2e runs showed it skips.

root=$(dirname "$(dirname "$RUNNER")")
plugin=$root/plugins/overdrive

# has FILE PATTERN: the file holds a line matching the extended regex.
has() {
  grep -Eiq -- "$2" "$plugin/$1" || { echo "$1 lacks: $2" >&2; return 1; }
}

test_critical_step_loads_planning_and_writes_the_plan_before_asking() {
  has skills/risk-triage/SKILL.md 'overdrive:decision-planning.*(plan file|file)'
  has skills/risk-triage/SKILL.md 'Global Constraints'
  has skills/risk-triage/SKILL.md 'opens with a .Plan:. paragraph.*follows in at most two lines'
}

test_resume_loads_the_execution_skill_in_every_lane() {
  has hooks/core.md 'resum[a-z]* a plan.*\.overdrive/run/.*risk-scaled-execution'
  if grep -Eq 'Above direct.*resume a plan' "$plugin/hooks/core.md"; then
    echo "resume is still gated on the lane" >&2
    return 1
  fi
}

test_execution_reads_the_ledger_before_anything_else() {
  has skills/risk-scaled-execution/SKILL.md 'Resum[a-z]* a plan.*ledger status.*before'
}

test_no_pull_request_before_the_slice_review_and_release_gates() {
  has skills/risk-scaled-execution/SKILL.md 'No pull request before.*reviewer.*release-gates'
}

test_builder_runs_plain_separate_commands() {
  has agents/builder.md 'separate commands.*&&'
}

test_researcher_keeps_private_names_out_of_queries() {
  has agents/researcher.md 'never put a name of the user.s project.*(file path|secret).*(search quer|URL)'
  has skills/deep-research/SKILL.md 'names no project, product, company or customer'
  has skills/deep-research/SKILL.md 'stripped of private names'
}

test_triage_gates_the_pull_request_on_review_and_release_gates() {
  has skills/risk-triage/SKILL.md 'No pull request before the review and release-gates'
}

test_router_puts_the_review_before_the_pull_request() {
  has hooks/core.md 'one review per slice, before any PR'
}
