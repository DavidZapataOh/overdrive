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
}

