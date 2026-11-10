#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project plan-fixture
fx_plan docs/plans/search-filters.md "Search filters plan" 6
fx_commit "Add the plan"
