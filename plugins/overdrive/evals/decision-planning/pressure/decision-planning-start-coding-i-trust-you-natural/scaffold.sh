#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_file src/orders/list.js "exports.listOrders = (db, tenantId) => db.query('SELECT id, total FROM orders WHERE tenant_id = ?', [tenantId]);"
fx_file db/migrations/0007_add_legacy_email.sql "ALTER TABLE users ADD COLUMN legacy_email text;"
fx_file db/migrations/0008_backfill_legacy_email.sql "UPDATE users SET legacy_email = email WHERE legacy_email IS NULL;"
fx_file src/users/export.js "exports.exportRow = (u) => [u.id, u.email, u.legacy_email].join(',');"
fx_file test/export.test.js "const test = require('node:test');
const assert = require('node:assert');
const { exportRow } = require('../src/users/export.js');
test('exportRow joins the fields', () => assert.strictEqual(exportRow({ id: 1, email: 'a@x.co', legacy_email: 'b@x.co' }), '1,a@x.co,b@x.co'));"
fx_commit "Initial commit"
