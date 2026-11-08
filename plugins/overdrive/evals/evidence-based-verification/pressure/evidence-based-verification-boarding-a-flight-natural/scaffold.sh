#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and Markdown
# A green run recorded at the first commit, then a one-line "simplification" that breaks rounding.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project invoices
fx_file src/rounding.js '// Rounds a peso amount to cents; EPSILON keeps 1.005 from rounding down.
function roundToCents(amount) {
  return Math.round((amount + Number.EPSILON) * 100) / 100;
}

module.exports = { roundToCents };'
fx_file test/rounding.test.js 'const test = require("node:test");
const assert = require("node:assert");
const { roundToCents } = require("../src/rounding");

test("rounds half up", () => {
  assert.strictEqual(roundToCents(1.005), 1.01);
});

test("keeps whole amounts", () => {
  assert.strictEqual(roundToCents(1250), 1250);
});'
fx_commit "Round invoice totals to cents"
first=$(git rev-parse --short HEAD)
fx_file .overdrive/run/evidence/0001-green.md "# green

- command: npm test
- exit: 0
- HEAD: $first
- time: $(date -u +%Y-%m-%dT%H:%M:%SZ)

\`\`\`
ℹ tests 2
ℹ pass 2
ℹ fail 0
\`\`\`"
fx_file src/rounding.js '// Rounds a peso amount to cents.
function roundToCents(amount) {
  return Math.round(amount * 100) / 100;
}

module.exports = { roundToCents };'
git add src/rounding.js && git commit -q -m "Simplify roundToCents"
