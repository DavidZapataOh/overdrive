#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project toolbox
fx_file turbo.json '{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "test": { "dependsOn": [] }
  }
}'
fx_file docs/plan.md '# Utility packages plan

## Global Constraints

Node built-in test runner only. One package per task under packages/<name>/, CommonJS, no dependencies. Tests live in packages/<name>/test/ and run with node --test.

### Task 1: pad

**Files:**
- Create: `packages/pad/index.js`
- Test: `packages/pad/test/pad.test.js`

`padLeft(value, width, fill)` returns the string left-padded to width with fill (default a space), exported as `module.exports = { padLeft }`.

### Task 2: uniq

**Files:**
- Create: `packages/uniq/index.js`
- Test: `packages/uniq/test/uniq.test.js`

`uniq(list)` removes repeated items and keeps the order of first occurrences, exported as `module.exports = { uniq }`.'
fx_commit "Add utility packages plan"
build_branch() {
  git switch -q -c "$1" main || return 1
  fx_file "packages/$2/index.js" "$3"
  fx_file "packages/$2/test/$2.test.js" "$4"
  fx_commit "Add $2 package" || return 1
  git switch -q main
}
build_branch task-1-pad pad "exports.padLeft = (value, width, fill = ' ') => String(value).padStart(width, fill);" "const test = require('node:test');
const assert = require('node:assert');
const { padLeft } = require('../index.js');
test('padLeft pads to width', () => assert.strictEqual(padLeft('7', 3, '0'), '007'));
test('padLeft keeps a long value', () => assert.strictEqual(padLeft('abcd', 2), 'abcd'));"
build_branch task-2-uniq uniq "exports.uniq = (list) => [...new Set(list)];" "const test = require('node:test');
const assert = require('node:assert');
const { uniq } = require('../index.js');
test('uniq keeps first occurrences', () => assert.deepStrictEqual(uniq([3, 1, 3, 2, 1]), [3, 1, 2]));
test('uniq keeps NaN once', () => assert.strictEqual(uniq([NaN, NaN]).length, 1));"
