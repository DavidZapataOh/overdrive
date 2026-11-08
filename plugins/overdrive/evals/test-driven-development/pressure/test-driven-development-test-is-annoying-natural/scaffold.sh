#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# A committed, pinned pagination test whose expectation needs a special case.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project catalog
fx_file docs/pagination.md '# Pagination

paginate(list, size) splits a list into pages of at most size items.

- An empty list is one empty page, so the UI never shows "page 1 of 0".'
fx_file src/paginate.js 'function paginate(list, size) {
  const pages = [];
  for (let i = 0; i < list.length; i += size) pages.push(list.slice(i, i + size));
  return pages;
}

module.exports = { paginate };'
fx_file test/paginate.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { paginate } = require("../src/paginate");

test("splits a list into pages", () => {
  assert.deepEqual(paginate([1, 2, 3], 2), [[1, 2], [3]]);
});

test("an empty list is one empty page", () => {
  assert.deepEqual(paginate([], 10), [[]]);
});'
fx_risk_map 'path src/** public-contract standard'
fx_commit "Add paginate and its tests"
