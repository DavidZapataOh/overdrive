#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_file src/orders/list.js "exports.listOrders = (db, tenantId) => db.query('SELECT id, total FROM orders WHERE tenant_id = ?', [tenantId]);"
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
git switch -q -c invoice-report
fx_file src/invoices/report.js "exports.listInvoices = (db, tenantId, year) => db.query('SELECT id, customer, total FROM invoices WHERE year = ?', [year]);
exports.totalFor = (rows) => rows.reduce((sum, r) => sum + r.total, 0);"
fx_file test/invoices.test.js "const test = require('node:test');
const assert = require('node:assert');
const { totalFor } = require('../src/invoices/report.js');
test('totalFor sums invoice totals', () => assert.strictEqual(totalFor([{ total: 2 }, { total: 3 }]), 5));"
fx_commit "Add the invoice report"
