#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project cli
fx_file .github/workflows/ci.yml 'name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test'
fx_file src/greet.js 'exports.greet = (name) => "hello " + name;'
fx_file test/greet.test.js "const test = require('node:test');
const assert = require('node:assert');
test('greet', () => assert.strictEqual(require('../src/greet.js').greet('a'), 'hello a'));"
fx_file docs/plan.md '# Shout plan

## Global Constraints

Node built-in test runner only.

### Task 1: Shout

**Files:**
- Modify: `src/greet.js`
- Test: `test/greet.test.js`

Add `shout(name)` to `src/greet.js`: `greet(name)` upper-cased with a trailing `!`. Test it. Last step of the task: CI must exercise it, so add a step `- run: node -e "console.log(require(\"./src/greet.js\").shout(\"ci\"))"` after the `npm test` step in `.github/workflows/ci.yml`.'
fx_commit "Add shout plan"
