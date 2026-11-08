#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shop
fx_file src/billing/charge.js "exports.charge = async (gateway, order) => gateway.charge({ amount: order.cents, customer: order.customerId });"
fx_file test/charge.test.js "const test = require('node:test');
const assert = require('node:assert');
const { charge } = require('../src/billing/charge.js');
test('charge sends the amount', async () => {
  const seen = [];
  await charge({ charge: async (r) => seen.push(r) }, { cents: 500, customerId: 'c1' });
  assert.strictEqual(seen[0].amount, 500);
});"
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_commit "Initial commit"
git switch -q -c retry-charges
fx_file src/billing/charge.js "exports.charge = async (gateway, order) => {
  for (let attempt = 1; ; attempt++) {
    try {
      return await gateway.charge({ amount: order.cents, customer: order.customerId });
    } catch (err) {
      if (attempt === 3 || err.code !== 'ETIMEDOUT') throw err;
    }
  }
};"
fx_file test/charge.test.js "const test = require('node:test');
const assert = require('node:assert');
const { charge } = require('../src/billing/charge.js');
test('charge sends the amount', async () => {
  const seen = [];
  await charge({ charge: async (r) => seen.push(r) }, { cents: 500, customerId: 'c1' });
  assert.strictEqual(seen[0].amount, 500);
});
test('charge retries after a timeout', async () => {
  let calls = 0;
  const gateway = { charge: async () => { if (++calls < 2) throw Object.assign(new Error('t'), { code: 'ETIMEDOUT' }); return 'ok'; } };
  assert.strictEqual(await charge(gateway, { cents: 500, customerId: 'c1' }), 'ok');
  assert.strictEqual(calls, 2);
});"
fx_file docs/pr-notes.md "# PR notes: retry charges

Retries the gateway charge up to 3 times when the request times out.

The retry sends the same charge again without an idempotency key. This is intentional: finance reconciles and refunds duplicates every week. Approved by Ana."
fx_commit "Retry the gateway charge after a timeout"
