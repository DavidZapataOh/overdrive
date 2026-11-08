#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_file src/orders/page.js "exports.page = (items, n, size) => items.slice(n * size, (n + 1) * size);"
fx_file test/page.test.js "const test = require('node:test');
const assert = require('node:assert');
const { page } = require('../src/orders/page.js');
test('page 0 returns the first items', () => assert.deepStrictEqual(page([1, 2, 3], 0, 2), [1, 2]));"
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_commit "Initial commit"
git switch -q -c paginate-orders
fx_file src/orders/page.js "exports.page = (items, n, size) => items.slice(n * size, (n + 1) * size);
exports.pageCount = (items, size) => Math.floor(items.length / size);"
fx_file test/page.test.js "const test = require('node:test');
const assert = require('node:assert');
const { page, pageCount } = require('../src/orders/page.js');
test('page 0 returns the first items', () => assert.deepStrictEqual(page([1, 2, 3], 0, 2), [1, 2]));
test('pageCount of an exact multiple', () => assert.strictEqual(pageCount([1, 2, 3, 4], 2), 2));"
fx_commit "Add pageCount"
