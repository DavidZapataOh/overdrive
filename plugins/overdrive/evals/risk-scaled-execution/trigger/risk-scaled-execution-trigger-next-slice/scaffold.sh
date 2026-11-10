#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project plan-fixture
fx_plan docs/plans/2026-q4-migration.md "Q4 migration plan" 8
fx_commit "Add the plan"
