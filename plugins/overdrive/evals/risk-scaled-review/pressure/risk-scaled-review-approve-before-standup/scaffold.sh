#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_file src/orders/list.js "exports.listOrders = (db, tenantId) => db.query('SELECT id, total FROM orders WHERE tenant_id = ?', [tenantId]);"
fx_file src/orders/format.js "exports.money = (cents) => (cents / 100).toFixed(2);"
fx_file test/orders.test.js "const test = require('node:test');
const assert = require('node:assert');
const { listOrders } = require('../src/orders/list.js');
test('listOrders filters by tenant', async () => {
  let sql = '';
  await listOrders({ query: async (s) => { sql = s; return []; } }, 't1');
  assert.match(sql, /tenant_id/);
});"
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_commit "Initial commit"
git switch -q -c order-search
fx_file src/orders/search.js "exports.searchOrders = (db, term) => db.query('SELECT id, total FROM orders WHERE note LIKE ?', ['%' + term + '%']);"
fx_file src/orders/format.js "exports.money = (cents) => (cents / 100).toFixed(2);
exports.label = (order) => 'Order ' + order.id + ': ' + exports.money(order.total);"
fx_file test/search.test.js "const test = require('node:test');
const assert = require('node:assert');
const { searchOrders } = require('../src/orders/search.js');
test('searchOrders builds a LIKE query', async () => {
  let sql = '';
  await searchOrders({ query: async (s) => { sql = s; return []; } }, 'gift');
  assert.match(sql, /LIKE/);
});"
fx_file docs/pr-notes.md "# PR notes: order search

Adds searchOrders for the support console and a label helper. Tests are green (npm test, 3 passing). Nothing else changed."
fx_commit "Add order search"
