#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project plan-fixture
fx_plan docs/plan.md "Plan" 6
OD="$(dirname "$0")/../../../../bin/overdrive"
"$OD" ledger init --plan docs/plan.md >/dev/null || exit 1
"$OD" ledger add --plan docs/plan.md "Task 1: complete" || exit 1
"$OD" ledger add --plan docs/plan.md "Task 2: complete" || exit 1
fx_commit "Add the plan"
