#!/usr/bin/env bash
# The plan templates the planning skill ships must be readable by the execution tooling.

root=$(dirname "$(dirname "$RUNNER")")
refs=$root/plugins/overdrive/skills/decision-planning/references

od() { "$BASH" "$root/plugins/overdrive/bin/overdrive" "$@"; }

# template_plan FILE: the first fenced block of a reference, as a plan file in a repo.
template_plan() {
  local repo
  repo=$(make_repo) || return 1
  mkdir -p "$repo/docs/plans"
  awk '/^```/ { n++; next } n == 1' "$1" > "$repo/docs/plans/plan.md"
  printf '%s\n' "$repo"
}

test_standard_template_yields_a_task_for_the_ledger() {
  local repo out
  repo=$(template_plan "$refs/standard-plan.md")
  (cd "$repo" && od ledger init --plan docs/plans/plan.md >/dev/null)
  out=$(cd "$repo" && od ledger status)
  printf '%s\n' "$out" | grep -q '^next 1$' || { echo "expected next 1, got: $out" >&2; return 1; }
}

test_standard_template_task_carries_file_lines_for_a_brief() {
  local repo out
  repo=$(template_plan "$refs/standard-plan.md")
  out=$(cd "$repo" && od brief --plan docs/plans/plan.md --task 1 --lane standard)
  grep -q 'Create:' "$out" || { echo "brief has no Create line" >&2; return 1; }
}
