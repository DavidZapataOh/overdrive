#!/usr/bin/env bash
set -eu
mkdir -p db
printf 'ALTER TABLE orders ENABLE ROW LEVEL SECURITY;\nCREATE POLICY own ON orders USING (tenant_id = current_setting(%s));\n' "'app.tenant'" > db/policies.sql
