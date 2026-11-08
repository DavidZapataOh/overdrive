#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project toolbox
fx_file src/config.js "exports.config = {
  name: 'toolbox',
};"
fx_file docs/plan.md '# Toolbox plan

## Global Constraints

Node built-in test runner only, CommonJS, no dependencies. Tests live in test/ and run with node --test.

### Task 1: retries

**Files:**
- Modify: `src/config.js`
- Test: `test/retries.test.js`

Add `retries: 3` to the exported config.

### Task 2: timeout

**Files:**
- Modify: `src/config.js`
- Test: `test/timeout.test.js`

Add `timeout: 30` to the exported config.

### Task 3: greet

**Files:**
- Create: `src/greet.js`
- Test: `test/greet.test.js`

`greet(name)` returns `Hello, <name>!`, exported as `module.exports = { greet }`.'
fx_commit "Add toolbox plan"
build_branch() {
  git switch -q -c "$1" main || return 1
  fx_file "$2" "$3"
  fx_file "$4" "$5"
  fx_commit "$6" || return 1
  git switch -q main
}
build_branch task-1-retries src/config.js "exports.config = {
  name: 'toolbox',
  retries: 3,
};" test/retries.test.js "const test = require('node:test');
const assert = require('node:assert');
const { config } = require('../src/config.js');
test('retries is 3', () => assert.strictEqual(config.retries, 3));" "Add retries to the config"
build_branch task-2-timeout src/config.js "exports.config = {
  name: 'toolbox',
  timeout: 30,
};" test/timeout.test.js "const test = require('node:test');
const assert = require('node:assert');
const { config } = require('../src/config.js');
test('timeout is 30', () => assert.strictEqual(config.timeout, 30));" "Add timeout to the config"
build_branch task-3-greet src/greet.js "exports.greet = (name) => \`Hello, \${name}!\`;" test/greet.test.js "const test = require('node:test');
const assert = require('node:assert');
const { greet } = require('../src/greet.js');
test('greet says hello', () => assert.strictEqual(greet('Ana'), 'Hello, Ana!'));" "Add greet"
