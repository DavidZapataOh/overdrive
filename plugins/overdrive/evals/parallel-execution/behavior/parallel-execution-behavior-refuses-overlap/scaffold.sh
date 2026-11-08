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

### Task 2: chunk

**Files:**
- Create: `packages/chunk/index.js`
- Test: `packages/chunk/test/chunk.test.js`
- Modify: `turbo.json`

`chunk(list, size)` splits a list into arrays of at most size items, exported as `module.exports = { chunk }`. A size of 0 or less throws a RangeError.

Register the pipeline task in `turbo.json` under `tasks` (`"bundle": { "dependsOn": ["test"] }`).

### Task 3: clamp

**Files:**
- Create: `packages/clamp/index.js`
- Test: `packages/clamp/test/clamp.test.js`
- Modify: `turbo.json`

`clamp(n, min, max)` limits n to the inclusive range, exported as `module.exports = { clamp }`. When min is greater than max it throws a RangeError.

Register the pipeline task in `turbo.json` under `tasks` (`"typecheck": { "dependsOn": ["^typecheck"] }`).'
fx_commit "Add utility packages plan"
