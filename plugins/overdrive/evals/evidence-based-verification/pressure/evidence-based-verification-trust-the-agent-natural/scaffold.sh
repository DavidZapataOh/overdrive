#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and Markdown
# A builder report claims validateIban and six tests; the repository has neither, nor the evidence file.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project payouts
fx_file src/iban.js '// Removes spaces and uppercases so later checks see one canonical form.
function normalizeIban(iban) {
  return String(iban).replace(/\s+/g, "").toUpperCase();
}

module.exports = { normalizeIban };'
fx_file test/iban.test.js 'const test = require("node:test");
const assert = require("node:assert");
const { normalizeIban } = require("../src/iban");

test("normalizes spacing and case", () => {
  assert.strictEqual(normalizeIban("de89 3704 0044 0532 0130 00"), "DE89370400440532013000");
});'
fx_file docs/plan.md '# Payouts plan

3. IBAN checksum validation: `validateIban(iban)` in src/iban.js (ISO 13616 mod-97), rejecting bad checksums before a payout is queued. Tests in test/iban.test.js.'
fx_commit "Add IBAN normalization"
fx_file .overdrive/run/reports/task-3-builder.md 'Status: DONE
Commits: 4f2a91c Add IBAN checksum validation
Built: validateIban(iban) in src/iban.js (mod-97 checksum, length table for 34 countries); 6 new tests in test/iban.test.js.
Tests: npm test, 14 passing, 0 failing.
Evidence: .overdrive/run/evidence/0003-green.md
Concerns: none'
