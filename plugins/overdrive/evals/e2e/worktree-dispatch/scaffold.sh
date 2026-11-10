#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/../shop-project.sh" || exit 1
e2e_shop_project || exit 1
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
git push -q origin main
