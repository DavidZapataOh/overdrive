#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# Sourced by the trigger scaffolds after _lib/fixtures.sh: a small Node shop with a passing suite,
# holding every path the trigger prompts name, so a prompt can be acted on instead of searched for.

td_trigger_repo() {
  fx_git_repo
  fx_node_project shop
  fx_file src/text.js 'function capitalize(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

module.exports = { capitalize };'
  fx_file src/price.js 'function total(items) {
  return Math.round(items.reduce((sum, item) => sum + item.price * item.qty, 0));
}

module.exports = { total };'
  fx_file src/coupon.js 'const { total } = require("./price");

function applyCoupon(items, coupon) {
  return coupon ? total(items) - coupon.value : total(items);
}

module.exports = { applyCoupon };'
  fx_file src/billing/refund.js 'function refund(order) {
  return order.paid;
}

module.exports = { refund };'
  fx_file docs/refunds.md '# Refunds

Orders paid within the last 30 days are refunded in full. Older orders get nothing back.'
  fx_file src/paginate.js 'function paginate(list, size) {
  const pages = [];
  for (let i = 0; i <= list.length; i += size) pages.push(list.slice(i, i + size));
  return pages;
}

module.exports = { paginate };'
  fx_file src/parse.js 'function parseDate(s) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
  return m ? new Date(Date.UTC(m[1], m[2] - 1, m[3])) : null;
}

module.exports = { parseDate };'
  fx_file src/server.js 'const http = require("node:http");

const server = http.createServer((req, res) => {
  res.statusCode = 404;
  res.end();
});

module.exports = { server };'
  fx_file src/http.js 'async function retry(fn, times) {
  for (let i = 0; i < times; i++) {
    try {
      return await fn();
    } catch (e) {
      await new Promise((r) => setTimeout(r, 1000));
    }
  }
}

module.exports = { retry };'
  fx_file src/validate.js 'module.exports = {};'
  fx_file src/carrito.js 'function agregar(carrito, item) {
  return [...carrito, item];
}

module.exports = { agregar };'
  fx_file test/cart.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { total } = require("../src/price");

test("total of an empty cart is 0", () => {
  assert.equal(total([]), 0);
});'
  fx_file test/queue.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");

test("queue keeps insertion order", async () => {
  const seen = [];
  await Promise.all([1, 2, 3].map((n) => new Promise((r) => setTimeout(() => { seen.push(n); r(); }, Math.random() * 20))));
  assert.deepEqual(seen, [1, 2, 3]);
});'
  fx_file README.md '# shop

Node checkout library. Tests run with npm test.'
  fx_commit "Add the shop library"
}
