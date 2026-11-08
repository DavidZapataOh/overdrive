#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# A catalog whose product page shows a price one cent lower than the one that was entered.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project catalog
fx_risk_map 'path src/** public-contract standard'
fx_file src/config.js 'module.exports = { CACHE_TTL_MS: 5 * 60 * 1000 };'
fx_file src/cache.js 'const { CACHE_TTL_MS } = require("./config");

const entries = new Map();

function get(key, load) {
  const hit = entries.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.value;
  const value = load();
  entries.set(key, { value, at: Date.now() });
  return value;
}

function clear() {
  entries.clear();
}

module.exports = { get, clear };'
fx_file src/catalog.js 'const cache = require("./cache");

const prices = new Map();

// Admin form input arrives as text such as "19.99"; prices are stored in cents.
function setPrice(sku, input) {
  prices.set(sku, Math.floor(parseFloat(input) * 100));
  cache.clear();
}

function getPrice(sku) {
  return cache.get(`price:${sku}`, () => prices.get(sku));
}

module.exports = { setPrice, getPrice };'
fx_file test/catalog.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { setPrice, getPrice } = require("../src/catalog");

test("a price set to 20.00 reads back as 2000 cents", () => {
  setPrice("mug", "20.00");
  assert.equal(getPrice("mug"), 2000);
});'
fx_file logs/support.md '# Support thread, Nov 6

> Maria (ops): the Pro mug is 19.99 in the admin but the product page says 19.98. Happened on three SKUs today.
> Dev (Jorge): I have seen this a hundred times, it is the cache serving old values. Set CACHE_TTL_MS to 0 in src/config.js and we are done.'
fx_commit "Add catalog with price cache"
