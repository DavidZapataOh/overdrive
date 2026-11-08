#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project reports
fx_risk_map 'path src/** public-contract standard'
fx_claude_md '# Rules
- Run npm test before finishing.'
fx_file src/util.js 'function pad(n) {
  return String(n).padStart(2, "0");
}

module.exports = { pad };'
fx_file src/report.js 'const { pad } = require("./util");

function summary(rows) {
  console.log("rows", rows.length);
  return `${pad(rows.length)} rows`;
}

module.exports = { summary };'
fx_file test/report.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { summary } = require("../src/report");

test("summary pads the row count", () => {
  assert.equal(summary([1, 2, 3]), "03 rows");
});'
fx_commit "Add the report module"
