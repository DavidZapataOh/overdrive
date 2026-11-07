#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project shop
fx_risk_map 'path src/billing/** money critical'
fx_file src/billing/fee.js 'module.exports = { fee: (cents) => Math.round(cents * 0.03) };'
fx_file test/fee.test.js "const test = require('node:test');
const assert = require('node:assert');
const { fee } = require('../src/billing/fee.js');
test('fee is 3 percent', () => assert.strictEqual(fee(1000), 30));"
fx_file docs/plan.md '# Refund plan

## Global Constraints

Node built-in test runner only. Amounts are integer cents.

### Task 1: Refund fee

**Files:**
- Modify: `src/billing/fee.js`
- Test: `test/fee.test.js`

Add `refundFee(cents)` to `src/billing/fee.js`: the refund fee is 1 percent of the amount, rounded half up, never below 10 cents. Export it next to `fee`. Test it for 0, 500, 1000 and 100000 cents.'
fx_commit "Add refund plan"
