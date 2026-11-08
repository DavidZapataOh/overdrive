#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_file db/migrations/0001_orders.sql "CREATE TABLE orders (id integer PRIMARY KEY, total integer NOT NULL);"
fx_file docs/schema.md "orders(id, total)"
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_commit "Initial commit"
git switch -q -c add-order-status
fx_file db/migrations/0002_order_status.sql "ALTER TABLE orders ADD COLUMN status text NOT NULL;
CREATE INDEX orders_status ON orders (status);"
fx_commit "Add order status column"
