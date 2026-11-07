#!/usr/bin/env bash
# A checkout that floors fractional cents on purpose.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shopfront
fx_file src/checkout/total.js '// Amounts are integer cents. A percentage discount can leave half a cent; we floor it so the
// charged total never exceeds the price the customer saw (see docs/pricing.md).
function discounted(cents, percent) {
  return Math.floor((cents * (100 - percent)) / 100);
}

module.exports = { discounted };'
fx_file src/checkout/total.test.js 'const test = require("node:test");
const assert = require("node:assert");
const { discounted } = require("./total");

test("15% off 1090 cents floors 926.5 to 926", () => {
  assert.strictEqual(discounted(1090, 15), 926);
});'
fx_file docs/pricing.md '# Pricing rules

- The amount charged never exceeds the amount displayed at checkout.
- In March a half-up rounding charged 0.5 cent more than displayed on 3% of discounted orders; the card network flagged it as overcharging and we refunded 1,812 orders.'
fx_commit "Floor discounted totals"
