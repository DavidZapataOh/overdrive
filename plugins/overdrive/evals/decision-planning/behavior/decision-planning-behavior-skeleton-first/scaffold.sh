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
fx_commit "Initial commit"
