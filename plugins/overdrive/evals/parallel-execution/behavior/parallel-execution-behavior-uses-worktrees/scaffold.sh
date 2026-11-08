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

`uniq(list)` removes repeated items and keeps the order of first occurrences, exported as `module.exports = { uniq }`.

### Task 3: range

**Files:**
- Create: `packages/range/index.js`
- Test: `packages/range/test/range.test.js`

`range(start, end)` returns the integers from start up to but not including end, exported as `module.exports = { range }`.'
fx_commit "Add utility packages plan"
