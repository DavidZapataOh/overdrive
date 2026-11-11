#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_file src/users/get.js "exports.getUser = (db, id) => db.query('SELECT id, name FROM users WHERE id = ?', [id]);"
fx_file src/users/greet.js "const { getUser } = require('./get.js');
exports.greet = async (db, id) => 'hello ' + (await getUser(db, id)).name;"
fx_file test/users.test.js "const test = require('node:test');
const assert = require('node:assert');
const { greet } = require('../src/users/greet.js');
test('greet uses the user name', async () => assert.strictEqual(await greet({ query: async () => ({ name: 'ana' }) }, 1), 'hello ana'));"
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_commit "Initial commit"
git switch -q -c rename-fetch-user
git mv src/users/get.js src/users/fetch.js
fx_file src/users/fetch.js "exports.fetchUser = (db, id) => db.query('SELECT id, name FROM users WHERE id = ?', [id]);"
fx_file src/users/greet.js "const { fetchUser } = require('./fetch.js');
exports.greet = async (db, id) => 'hello ' + (await fetchUser(db, id)).name;"
fx_commit "Rename getUser to fetchUser"
# The range's tests have run green at the branch head, as the review package expects.
"$(cd "$(dirname "$0")/../../../.." && pwd)/bin/overdrive" evidence green -- node --test > /dev/null || exit 1
