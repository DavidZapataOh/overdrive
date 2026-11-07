#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shop
fx_file src/billing/proration.js 'exports.prorate = (cents, daysLeft, daysInPeriod) => Math.round((cents * daysLeft) / daysInPeriod);'
fx_file docs/plan.md '### Task 4: Proration rounding

**Files:**
- Modify: `src/billing/proration.js`

Round proration to whole cents.'
fx_commit "Initial commit"
git switch -q -c proration-rounding
fx_file src/billing/proration.js 'exports.prorate = (cents, daysLeft, daysInPeriod) => Math.floor((cents * daysLeft) / daysInPeriod);'
fx_commit "Floor proration to whole cents"
