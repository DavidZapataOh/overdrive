#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_file src/orders/list.js "exports.listOrders = (db, tenantId) => db.query('SELECT id, total FROM orders WHERE tenant_id = ?', [tenantId]);"
fx_file README.md "# Partner portal

Express service for partner invoices. No auth or payments yet."
fx_commit "Initial commit"
