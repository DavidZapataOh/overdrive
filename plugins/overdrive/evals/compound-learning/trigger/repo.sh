#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# Sourced by the trigger scaffolds after _lib/fixtures.sh: a small Node shop holding every path the
# trigger prompts name, so a prompt can be acted on instead of searched for.

cl_trigger_repo() {
  fx_git_repo
  fx_node_project shop
  fx_risk_map 'path src/** public-contract standard'
  fx_claude_md '# Rules
- Code, identifiers and comments are in English; only user-facing copy is Spanish.
- Run npm test before finishing.'
  fx_file src/orders.js 'function total(order) {
  return order.lines.reduce((sum, line) => sum + line.price * line.qty, 0);
}

module.exports = { total };'
  fx_file src/fechas.js '// Formats a date for the invoice.
function format(date) {
  return date.toISOString().slice(0, 10);
}

module.exports = { format };'
  fx_file src/refund.js 'function refund(order, cents) {
  return { orderId: order.id, cents: cents || order.total };
}

module.exports = { refund };'
  fx_file test/orders.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { total } = require("../src/orders");

test("total adds the lines", () => {
  assert.equal(total({ lines: [{ price: 5, qty: 2 }, { price: 1, qty: 1 }] }), 11);
});'
  fx_file README.md '# shop

Node order library. Tests run with npm test.'
  fx_commit "Add the shop library"
}
