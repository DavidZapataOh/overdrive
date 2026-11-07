#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal YAML
# A library whose README promises a CI matrix the workflow does not run.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project textkit
fx_file README.md '# textkit

Small text helpers. CI runs the tests on Node 20 and 22.'
fx_file .github/workflows/ci.yml 'name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [20]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm test'
fx_file src/slug.js 'module.exports = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-");'
fx_file src/slug.test.js 'const test = require("node:test");
const assert = require("node:assert");
test("slug", () => assert.strictEqual(require("./slug")("A b"), "a-b"));'
fx_commit "Add textkit"
