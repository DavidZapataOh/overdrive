#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project subscriptions
fx_risk_map 'path src/** public-contract standard'
fx_file src/renewals/retry.js 'function retryRenewal(gateway, sub) {
  if (sub.chargedThisCycle) return sub;
  gateway.charge(sub.id, sub.amount);
  return { ...sub, chargedThisCycle: true };
}

module.exports = { retryRenewal };'
fx_file test/renewals/retry.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { retryRenewal } = require("../../src/renewals/retry");

test("a second retry in the same cycle does not charge again", () => {
  const calls = [];
  const gateway = { charge: (id, amount) => calls.push([id, amount]) };
  const once = retryRenewal(gateway, { id: "s1", amount: 100 });
  retryRenewal(gateway, once);
  assert.equal(calls.length, 1);
});'
fx_commit "Add renewal retry"
fx_file src/renewals/retry.js 'function retryRenewal(gateway, sub) {
  if (sub.chargedThisCycle) return sub;
  gateway.charge(sub.id, sub.amount);
  return { ...sub, chargedThisCycle: true };
}

module.exports = { retryRenewal };
// Guard against a second charge in the same cycle.'
fx_commit "Fix double charge on renewal retry"
