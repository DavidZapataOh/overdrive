#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and Markdown
# Sourced by the behavior scaffolds after _lib/fixtures.sh: a small Node text library with a
# passing suite, and the CLI path used to pin tests.

# The plugin root, from a scaffold at evals/<skill>/behavior/<case>/scaffold.sh.
td_cli() {
  printf '%s\n' "$(cd "$(dirname "$0")/../../../.." && pwd)/bin/overdrive"
}

td_text_project() {
  fx_git_repo
  fx_node_project textkit
  fx_file src/text.js 'function capitalize(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function slugify(s) {
  return s.toLowerCase().replace(/ /g, "-");
}

module.exports = { capitalize, slugify };'
  fx_file test/text.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { capitalize } = require("../src/text");

test("capitalize uppercases the first letter", () => {
  assert.equal(capitalize("hello"), "Hello");
});'
  fx_file docs/text.md '# Text helpers

- `capitalize(s)` uppercases the first letter.
- `slugify(s)` lowercases, drops everything except letters, digits and spaces, and joins the words with single dashes: `slugify("  Hello,  World! ")` is `"hello-world"`.'
  fx_file .editorconfig 'root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf'
  fx_commit "Add text helpers"
}
