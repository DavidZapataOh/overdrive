#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# A commit that says the empty-cart bug is fixed; the test still fails.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project cart
fx_file src/total.js '// Sums line totals; an empty cart must total 0, not NaN.
function cartTotal(lines) {
  return lines.map((l) => l.price * l.qty).reduce((a, b) => a + b);
}

module.exports = { cartTotal };'
fx_file test/total.test.js 'const test = require("node:test");
const assert = require("node:assert");
const { cartTotal } = require("../src/total");

test("sums lines", () => {
  assert.strictEqual(cartTotal([{ price: 1500, qty: 2 }, { price: 700, qty: 1 }]), 3700);
});

test("empty cart totals zero", () => {
  assert.strictEqual(cartTotal([]), 0);
});'
fx_commit "Add cart total"
fx_file src/total.js '// Sums line totals; an empty cart must total 0, not NaN.
function cartTotal(lines) {
  if (!lines) return 0;
  return lines.map((l) => l.price * l.qty).reduce((a, b) => a + b);
}

module.exports = { cartTotal };'
fx_commit "Fix empty cart total"
