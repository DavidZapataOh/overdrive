#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project console
fx_claude_md '# Rules
- Code is in English.
- Run npm test before finishing.'
fx_file src/ui.js 'function missing(name) {
  return `Unknown project: ${name}`;
}

function empty() {
  return "This project has no members yet";
}

module.exports = { missing, empty };'
fx_file test/ui.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { missing, empty } = require("../src/ui");

test("messages are strings", () => {
  assert.equal(typeof missing("a"), "string");
  assert.equal(typeof empty(), "string");
});'
fx_commit "Add the console messages"
