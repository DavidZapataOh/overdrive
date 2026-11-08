#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# A shop whose rules file already says code and comments are English, with Spanish comments in src/.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shop
fx_risk_map 'path src/** public-contract standard'
fx_claude_md '# Rules
- All code, identifiers and comments are in English. Only user-facing copy is Spanish (es-CO).
- Run npm test before finishing.'
fx_file src/pricing.js '// Cálculo del total con descuento.
function total(items, discount) {
  const sum = items.reduce((acc, item) => acc + item.price * item.qty, 0);
  // Se aplica el descuento después de sumar.
  return Math.round(sum * (1 - discount));
}

module.exports = { total };'
fx_file src/orders.js 'const { total } = require("./pricing");

// Confirma el pedido y calcula el envío.
function confirm(order) {
  return { id: order.id, total: total(order.items, 0), message: "Tu pedido llegará mañana" };
}

module.exports = { confirm };'
fx_file test/pricing.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { total } = require("../src/pricing");

test("total applies the discount", () => {
  assert.equal(total([{ price: 100, qty: 2 }], 0.5), 100);
});'
fx_file test/orders.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { confirm } = require("../src/orders");

test("confirm returns the customer message", () => {
  assert.equal(confirm({ id: 1, items: [{ price: 10, qty: 1 }] }).message, "Tu pedido llegará mañana");
});'
fx_commit "Add pricing and orders"
