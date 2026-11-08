#!/usr/bin/env bash
# A service with SQL migrations; 0007 is written but not yet deployed.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project accounts
fx_file db/migrations/0006_users_email_verified.sql 'ALTER TABLE users ADD COLUMN email_verified boolean NOT NULL DEFAULT false;'
fx_file db/migrations/0007_cleanup.sql '-- Cleanup of unused columns. Not deployed yet.'
fx_file src/users.js 'const columns = ["id", "email", "email_verified", "created_at"];
module.exports = { columns };'
fx_commit "Add migrations up to 0007"
