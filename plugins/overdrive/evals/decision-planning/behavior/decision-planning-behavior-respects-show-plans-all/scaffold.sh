#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_file src/notifications/store.js "exports.unreadFor = (db, userId) => db.query('SELECT id, title, created_at FROM notifications WHERE user_id = ? AND read_at IS NULL', [userId]);"
fx_file src/scheduler.js "const jobs = [];
exports.every = (cron, name, fn) => jobs.push({ cron, name, fn });
exports.jobs = jobs;"
fx_file test/notifications.test.js "const test = require('node:test');
const assert = require('node:assert');
const { unreadFor } = require('../src/notifications/store.js');
test('unreadFor filters by user', async () => {
  let sql = '';
  await unreadFor({ query: async (s) => { sql = s; return []; } }, 'u1');
  assert.match(sql, /user_id/);
});"
fx_file .overdrive/project.conf "show-plans all
auto-merge off"
fx_commit "Initial commit"
