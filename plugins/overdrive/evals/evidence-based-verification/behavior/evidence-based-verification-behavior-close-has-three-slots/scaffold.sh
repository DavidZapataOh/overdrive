#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and Markdown
# A finished CSV export with passing tests and an API doc that does not mention it yet.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project reports
fx_file docs/api.md '# Reports API

Source of truth for every exported function in src/. Update it in the same change as the code.

## toJson(rows)

Returns the rows as a JSON string.'
fx_file src/export.js '// Quotes every field so commas and quotes inside values survive a round trip.
function toCsv(rows) {
  const quote = (v) => `"${String(v).replace(/"/g, "\"\"")}"`;
  return rows.map((r) => r.map(quote).join(",")).join("\n");
}

function toJson(rows) {
  return JSON.stringify(rows);
}

module.exports = { toCsv, toJson };'
fx_file test/export.test.js 'const test = require("node:test");
const assert = require("node:assert");
const { toCsv } = require("../src/export");

test("quotes fields with commas and quotes", () => {
  assert.strictEqual(toCsv([["a,b", "say \"hi\""]]), "\"a,b\",\"say \"\"hi\"\"\"");
});'
fx_commit "Add CSV export"
