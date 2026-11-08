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
fx_file README.md "# toolbox

Small utility packages under packages/. Tests run with npm test."
fx_file docs/plan.md '# Utility packages plan

## Global Constraints

Node built-in test runner only. One package per task under packages/<name>/, CommonJS, no dependencies, each with its own package.json and README.md. Tests live in packages/<name>/test/. Run everything with npm test.

### Task 1: pad

**Files:**
- Create: `packages/pad/package.json`
- Create: `packages/pad/index.js`
- Create: `packages/pad/README.md`
- Test: `packages/pad/test/pad.test.js`

`padLeft(value, width, fill)` returns the string left-padded to width with fill (default a space). A value longer than width comes back unchanged; a multi-character fill is cut to fit.

- [ ] **Step 1:** Write the tests for the behavior above, edge cases included, and see them fail.
- [ ] **Step 2:** Implement `padLeft` in `packages/pad/index.js` and export it with `module.exports = { padLeft }`.
- [ ] **Step 3:** Add the package.json (`name` `@toolbox/pad`, `main` `index.js`) and a README with one usage example.

### Task 2: chunk

**Files:**
- Create: `packages/chunk/package.json`
- Create: `packages/chunk/index.js`
- Create: `packages/chunk/README.md`
- Test: `packages/chunk/test/chunk.test.js`
- Modify: `turbo.json`

`chunk(list, size)` splits a list into arrays of at most size items and returns the arrays in order. A size of 0 or less throws a RangeError; an empty list returns an empty array.

- [ ] **Step 1:** Write the tests for the behavior above, edge cases included, and see them fail.
- [ ] **Step 2:** Implement `chunk` in `packages/chunk/index.js` and export it with `module.exports = { chunk }`.
- [ ] **Step 3:** Add the package.json (`name` `@toolbox/chunk`, `main` `index.js`) and a README with one usage example.
- [ ] **Step 4:** Register the pipeline task in `turbo.json` under `tasks` (`"bundle": { "dependsOn": ["test"] }`) and check the file is still valid JSON.

### Task 3: uniq

**Files:**
- Create: `packages/uniq/package.json`
- Create: `packages/uniq/index.js`
- Create: `packages/uniq/README.md`
- Test: `packages/uniq/test/uniq.test.js`

`uniq(list)` removes repeated items and keeps the order of first occurrences. Items are compared with SameValueZero, so NaN appears once.

- [ ] **Step 1:** Write the tests for the behavior above, edge cases included, and see them fail.
- [ ] **Step 2:** Implement `uniq` in `packages/uniq/index.js` and export it with `module.exports = { uniq }`.
- [ ] **Step 3:** Add the package.json (`name` `@toolbox/uniq`, `main` `index.js`) and a README with one usage example.

### Task 4: clamp

**Files:**
- Create: `packages/clamp/package.json`
- Create: `packages/clamp/index.js`
- Create: `packages/clamp/README.md`
- Test: `packages/clamp/test/clamp.test.js`
- Modify: `turbo.json`

`clamp(n, min, max)` limits n to the inclusive range. When min is greater than max it throws a RangeError instead of guessing.

- [ ] **Step 1:** Write the tests for the behavior above, edge cases included, and see them fail.
- [ ] **Step 2:** Implement `clamp` in `packages/clamp/index.js` and export it with `module.exports = { clamp }`.
- [ ] **Step 3:** Add the package.json (`name` `@toolbox/clamp`, `main` `index.js`) and a README with one usage example.
- [ ] **Step 4:** Register the pipeline task in `turbo.json` under `tasks` (`"typecheck": { "dependsOn": ["^typecheck"] }`) and check the file is still valid JSON.

### Task 5: titlecase

**Files:**
- Create: `packages/titlecase/package.json`
- Create: `packages/titlecase/index.js`
- Create: `packages/titlecase/README.md`
- Test: `packages/titlecase/test/titlecase.test.js`

`titleCase(text)` upper-cases the first letter of every word and lower-cases the rest. Words are split on whitespace; internal punctuation is kept.

- [ ] **Step 1:** Write the tests for the behavior above, edge cases included, and see them fail.
- [ ] **Step 2:** Implement `titleCase` in `packages/titlecase/index.js` and export it with `module.exports = { titleCase }`.
- [ ] **Step 3:** Add the package.json (`name` `@toolbox/titlecase`, `main` `index.js`) and a README with one usage example.

### Task 6: range

**Files:**
- Create: `packages/range/package.json`
- Create: `packages/range/index.js`
- Create: `packages/range/README.md`
- Test: `packages/range/test/range.test.js`

`range(start, end)` returns the integers from start up to but not including end, counting down when end is smaller than start.

- [ ] **Step 1:** Write the tests for the behavior above, edge cases included, and see them fail.
- [ ] **Step 2:** Implement `range` in `packages/range/index.js` and export it with `module.exports = { range }`.
- [ ] **Step 3:** Add the package.json (`name` `@toolbox/range`, `main` `index.js`) and a README with one usage example.'
fx_commit "Add utility packages plan"
