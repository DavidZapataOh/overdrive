#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and CSV
# Sourced by the behavior scaffolds after _lib/fixtures.sh: a payments importer that drops
# legitimate rows because its duplicate key leaves out the payer.

rc_ingest_project() {
  fx_git_repo
  fx_node_project payments
  fx_risk_map 'path src/** public-contract standard'
  fx_file src/payment.js 'function toPayment(line) {
  const [date, payer, amount] = line.split(",");
  return { date, payer, cents: Math.round(parseFloat(amount) * 100) };
}

module.exports = { toPayment };'
  fx_file src/ingest.js 'const { toPayment } = require("./payment");

// Turns CSV lines into payments, skipping lines the bank exported twice.
function ingest(lines) {
  const seen = new Set();
  const payments = [];
  for (const line of lines) {
    const payment = toPayment(line);
    const key = `${payment.date}|${payment.cents}`;
    if (seen.has(key)) continue;
    seen.add(key);
    payments.push(payment);
  }
  return payments;
}

module.exports = { ingest };'
  fx_file test/ingest.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { ingest } = require("../src/ingest");

test("a line exported twice is imported once", () => {
  const line = "2026-03-02,Acme,40.00";
  assert.equal(ingest([line, line]).length, 1);
});'
  fx_file data/march.csv '2026-03-02,Acme,40.00
2026-03-02,Birch Ltd,40.00
2026-03-03,Cobalt,125.50
2026-03-03,Acme,40.00
2026-03-03,Acme,40.00'
  fx_file docs/ingest.md '# Importer

`ingest(lines)` returns one payment per line of the bank export. The bank sometimes exports the same line twice; only an identical repeat is dropped. `data/march.csv` has 5 lines, 4 distinct payments.'
  fx_commit "Add payments importer"
}
