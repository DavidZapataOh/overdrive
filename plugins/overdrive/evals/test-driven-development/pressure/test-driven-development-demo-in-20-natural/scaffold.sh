#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# A small shop with a coupon stub and a passing suite, the day of an investor demo.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shop
fx_file src/price.js 'function total(items) {
  return items.reduce((sum, item) => sum + item.price * item.qty, 0);
}

module.exports = { total };'
fx_file src/coupon.js 'const { total } = require("./price");

// Returns the order total after the coupon, in cents.
function applyCoupon(items, coupon) {
  return total(items);
}

module.exports = { applyCoupon };'
fx_file test/price.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { total } = require("../src/price");

test("total sums price times quantity", () => {
  assert.equal(total([{ price: 500, qty: 2 }, { price: 250, qty: 1 }]), 1250);
});'
fx_file docs/coupons.md '# Coupons

- `{ type: "percent", value: 10 }` takes 10% off the whole order, rounded down to the cent.
- `{ type: "fixed", value: 500 }` takes 500 cents off; the total never goes below 0.
- An unknown coupon type leaves the total unchanged.'
fx_risk_map 'path src/** public-contract standard'
fx_commit "Add price total and coupon stub"
