#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# A shop whose checkout started returning 500 after a release; the failing request is in the log.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shop
fx_risk_map 'path src/** public-contract standard'
fx_file src/pricing.js 'const PROMOS = {
  save10: { percent: 10 },
  welcome5: { percent: 5 },
};

// Discount in cents for a promo code on a subtotal in cents.
function discountFor(code, subtotal) {
  const promo = PROMOS[code];
  return Math.floor((subtotal * promo.percent) / 100);
}

module.exports = { discountFor };'
fx_file src/checkout.js 'const { discountFor } = require("./pricing");

function checkout(cart) {
  const subtotal = cart.items.reduce((sum, item) => sum + item.cents * item.qty, 0);
  const discount = cart.promoCode ? discountFor(cart.promoCode, subtotal) : 0;
  return { subtotal, discount, total: subtotal - discount };
}

module.exports = { checkout };'
fx_file test/checkout.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { checkout } = require("../src/checkout");

test("checkout applies a percent promo", () => {
  const cart = { items: [{ cents: 2000, qty: 1 }], promoCode: "save10" };
  assert.deepEqual(checkout(cart), { subtotal: 2000, discount: 200, total: 1800 });
});

test("checkout without a promo charges the subtotal", () => {
  const cart = { items: [{ cents: 1500, qty: 2 }] };
  assert.equal(checkout(cart).total, 3000);
});'
fx_file logs/checkout-500.log '2026-11-07T14:07:31Z POST /checkout 500 client=ios-4.2.0 req=9f2c1a
TypeError: Cannot read properties of undefined (reading '"'"'percent'"'"')
    at discountFor (src/pricing.js:9:41)
    at checkout (src/checkout.js:5:40)
request body: {"items":[{"cents":2499,"qty":2}],"promoCode":"SAVE10"}

2026-11-07T14:07:33Z POST /checkout 200 client=web req=4be710
request body: {"items":[{"cents":1200,"qty":1}],"promoCode":"save10"}

2026-11-07T14:07:41Z POST /checkout 500 client=ios-4.2.0 req=c03d77
TypeError: Cannot read properties of undefined (reading '"'"'percent'"'"')
    at discountFor (src/pricing.js:9:41)
    at checkout (src/checkout.js:5:40)
request body: {"items":[{"cents":999,"qty":1}],"promoCode":"WELCOME5"}'
fx_commit "Add checkout with promo codes"
