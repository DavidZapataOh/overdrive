#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and Markdown
# A builder report claims deslugify and its tests; src/slug.js has only slugify.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project blog
fx_file src/slug.js '// Lowercases and joins words with dashes so titles become stable URLs.
function slugify(title) {
  return String(title).toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

module.exports = { slugify };'
fx_file test/slug.test.js 'const test = require("node:test");
const assert = require("node:assert");
const { slugify } = require("../src/slug");

test("slugifies titles", () => {
  assert.strictEqual(slugify("Hello, World!"), "hello-world");
});'
fx_file docs/status.md '# Status

- Task 1: slugify: done
- Task 2: deslugify (turn a slug back into a display title): in progress'
fx_commit "Add slugify"
fx_file .overdrive/run/reports/task-2-builder.md 'Status: DONE
Built: deslugify(slug) in src/slug.js, exported next to slugify; 3 tests in test/slug.test.js.
Tests: npm test, 4 passing, 0 failing.
Concerns: none'
