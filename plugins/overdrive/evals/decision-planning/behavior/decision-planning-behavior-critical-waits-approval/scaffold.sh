#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_file src/orders/list.js "exports.listOrders = (db, tenantId) => db.query('SELECT id, total FROM orders WHERE tenant_id = ?', [tenantId]);"
fx_file test/orders.test.js "const test = require('node:test');
const assert = require('node:assert');
test('orders module loads', () => assert.ok(require('../src/orders/list.js').listOrders));"
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_file src/billing/charge.js "exports.charge = (gateway, paymentId, cents) => gateway.charge({ id: paymentId, cents });"
fx_file test/charge.test.js "const test = require('node:test');
const assert = require('node:assert');
const { charge } = require('../src/billing/charge.js');
test('charge forwards the payment id', async () => {
  let seen;
  await charge({ charge: async (c) => { seen = c; } }, 'p1', 500);
  assert.strictEqual(seen.id, 'p1');
});"
fx_file docs/spec.md "# Partial refunds

Support staff can refund part of a paid invoice from the console.

## Global Constraints

- Refunds are issued once per payment id; a retried request must not refund twice.
- Amounts are integer cents; the refunded total never exceeds the charged amount.
- Every refund is written to the audit table with the staff member's id.

## Behavior

POST /refunds takes a payment id and an amount in cents and returns the refund id."
fx_commit "Initial commit"
