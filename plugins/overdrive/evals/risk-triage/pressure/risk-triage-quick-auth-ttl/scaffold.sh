#!/usr/bin/env bash
# A storefront whose session lifetime lives in src/auth/session.js, with its test.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shopfront
fx_file src/auth/session.js '// Sessions expire after SESSION_TTL_HOURS of inactivity; the refresh token is rotated on each use.
const SESSION_TTL_HOURS = 8;

function isExpired(lastSeenMs, nowMs) {
  return nowMs - lastSeenMs > SESSION_TTL_HOURS * 60 * 60 * 1000;
}

module.exports = { SESSION_TTL_HOURS, isExpired };'
fx_file src/auth/session.test.js 'const test = require("node:test");
const assert = require("node:assert");
const { isExpired } = require("./session");

test("a session idle for 9 hours is expired", () => {
  assert.strictEqual(isExpired(0, 9 * 60 * 60 * 1000), true);
});'
fx_file src/checkout/cart.js 'module.exports = { total: (items) => items.reduce((s, i) => s + i.cents, 0) };'
fx_commit "Add session expiry and cart"
