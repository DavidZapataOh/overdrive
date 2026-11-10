#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and YAML
# Sourced by the scaffolds after _lib/fixtures.sh: a small shop on main with a local bare remote
# named origin, a billing module the risk map marks critical, and a plain API folder.

# e2e_shop_project [AUTO_MERGE]
e2e_shop_project() {
  local merge=${1:-off}
  export GIT_AUTHOR_DATE='2026-01-05T10:00:00+00:00' GIT_COMMITTER_DATE='2026-01-05T10:00:00+00:00'
  fx_git_repo
  printf '/.remote.git\n' >> .git/info/exclude
  fx_node_project shop
  fx_risk_map 'path src/billing/** money critical' 'path src/http/** request-validation standard'
  fx_file .overdrive/project.conf "show-plans critical
auto-merge $merge"
  fx_file README.md '# Shop

A small shop library. Run the tests with npm test.'
  fx_file src/billing/invoice.js '// Amounts are integer cents.
function lineTotal(unitCents, quantity) {
  return Math.floor(unitCents * quantity);
}

module.exports = { lineTotal };'
  fx_file test/invoice.test.js "const test = require('node:test');
const assert = require('node:assert');
const { lineTotal } = require('../src/billing/invoice.js');

test('multiplies unit price by quantity', () => {
  assert.strictEqual(lineTotal(250, 3), 750);
});"
  fx_file src/api/health.js 'function health() {
  return { status: 200, body: { ok: true } };
}

module.exports = { health };'
  fx_file test/health.test.js "const test = require('node:test');
const assert = require('node:assert');
const { health } = require('../src/api/health.js');

test('health is ok', () => {
  assert.deepStrictEqual(health(), { status: 200, body: { ok: true } });
});"
  fx_file .github/workflows/ci.yml 'name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test'
  : > .gh-calls.log
  fx_commit "Add invoice totals and health endpoint"
  git init -q --bare -b main .remote.git || return 1
  git remote add origin .remote.git || return 1
  git push -q -u origin main || return 1
  git remote set-head origin main > /dev/null || return 1
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
}
