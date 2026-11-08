#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and Markdown
# Sourced by the behavior scaffolds after _lib/fixtures.sh: a small time-series library whose
# moving average returns one window too many, with a suite that never looks at the end of the result.

rc_series_project() {
  fx_git_repo
  fx_node_project metrics
  fx_risk_map 'path src/** public-contract standard'
  fx_file src/series.js 'function sum(values) {
  return values.reduce((total, value) => total + value, 0);
}

// Average of every full window of `window` consecutive values.
function movingAverage(values, window) {
  const out = [];
  for (let i = 0; i <= values.length - window + 1; i++) {
    out.push(sum(values.slice(i, i + window)) / window);
  }
  return out;
}

module.exports = { sum, movingAverage };'
  fx_file test/series.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { sum, movingAverage } = require("../src/series");

test("sum adds the values", () => {
  assert.equal(sum([1, 2, 3]), 6);
});

test("movingAverage starts with the first full window", () => {
  assert.equal(movingAverage([10, 20, 30, 40], 2)[0], 15);
});'
  fx_file docs/series.md '# Series helpers

- `movingAverage(values, window)` returns one average per full window, so `values.length - window + 1` numbers: `movingAverage([1, 2, 3, 4, 5], 3)` is `[2, 3, 4]`.'
  fx_commit "Add series helpers"
}
