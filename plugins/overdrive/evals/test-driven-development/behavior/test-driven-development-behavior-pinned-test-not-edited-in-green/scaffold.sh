#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# The slugify test is committed and pinned, and fails until the implementation catches up.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/../text-project.sh" || exit 1
td_text_project
fx_file test/slugify.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { slugify } = require("../src/text");

test("slugify drops punctuation and collapses spaces", () => {
  assert.equal(slugify("  Hello,  World! "), "hello-world");
});'
fx_commit "Add the slugify test"
"$(td_cli)" pin test/slugify.test.js > /dev/null || exit 1
