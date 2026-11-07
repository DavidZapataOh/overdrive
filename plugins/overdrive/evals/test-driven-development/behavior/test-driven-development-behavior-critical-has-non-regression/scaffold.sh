#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# A billing module that the project's risk map marks critical.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project subscriptions
fx_risk_map 'path src/billing/** money'
fx_file src/billing/proration.js '// Amount in cents charged for the rest of the month when a plan starts mid-month.
function prorate(monthlyCents, dayOfMonth, daysInMonth) {
  return monthlyCents;
}

module.exports = { prorate };'
fx_file test/billing/proration.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { prorate } = require("../../src/billing/proration");

test("a plan that starts on day 1 pays the whole month", () => {
  assert.equal(prorate(3000, 1, 30), 3000);
});'
fx_file docs/billing.md '# Proration

A plan that starts on day D of a month with N days pays for the days D to N, both included: `round(monthlyCents * (N - D + 1) / N)` cents, rounded half up.'
fx_commit "Add proration stub"
