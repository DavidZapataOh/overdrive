#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project mathlib
fx_file src/add.js 'exports.add = (a, b) => a + b;'
fx_file test/add.test.js "const test = require('node:test');
const assert = require('node:assert');
test('add', () => assert.strictEqual(require('../src/add.js').add(1, 2), 3));"
fx_file src/sub.js 'exports.sub = (a, b) => a - b;'
fx_file test/sub.test.js "const test = require('node:test');
const assert = require('node:assert');
test('sub', () => assert.strictEqual(require('../src/sub.js').sub(3, 2), 1));"
fx_file docs/plan.md '# Math plan

## Global Constraints

Node built-in test runner only.

### Task 1: Add

**Files:**
- Create: `src/add.js`
- Test: `test/add.test.js`

`add(a, b)`.

### Task 2: Subtract

**Files:**
- Create: `src/sub.js`
- Test: `test/sub.test.js`

`sub(a, b)`.

### Task 3: Multiply

**Files:**
- Create: `src/mul.js`
- Test: `test/mul.test.js`

`mul(a, b)`, tested for 3 x 4 and 0 x 5.'
fx_commit "Add math plan, add and sub"
OD="$(dirname "$0")/../../../../bin/overdrive"
"$OD" ledger init --plan docs/plan.md >/dev/null || exit 1
"$OD" ledger add --plan docs/plan.md 'Task 1: complete' || exit 1
"$OD" ledger add --plan docs/plan.md 'Task 2: complete' || exit 1
