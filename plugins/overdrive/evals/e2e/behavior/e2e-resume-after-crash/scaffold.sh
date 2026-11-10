#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/../../shop-project.sh" || exit 1
e2e_shop_project || exit 1
fx_file docs/plan.md '# Text helpers plan

## Global Constraints

Node built-in test runner only. CommonJS, one helper per file in src/http/text/, tests in test/.

### Task 1: capitalize

**Files:**
- Create: `src/http/text/capitalize.js`
- Test: `test/capitalize.test.js`

`capitalize(text)` upper-cases the first letter and leaves the rest as is, exported as `module.exports = { capitalize }`.

### Task 2: slugify

**Files:**
- Create: `src/http/text/slugify.js`
- Test: `test/slugify.test.js`

`slugify(text)` lower-cases, trims, and joins words with single hyphens: `slugify("  Hello  World ")` is `hello-world`. Exported as `module.exports = { slugify }`.

### Task 3: truncate

**Files:**
- Create: `src/http/text/truncate.js`
- Test: `test/truncate.test.js`

`truncate(text, max)` returns the text unchanged when it fits, otherwise the first `max - 1` characters followed by `…`. Exported as `module.exports = { truncate }`.'
fx_file src/http/text/capitalize.js 'function capitalize(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}

module.exports = { capitalize };'
fx_file test/capitalize.test.js "const test = require('node:test');
const assert = require('node:assert');
const { capitalize } = require('../src/http/text/capitalize.js');

test('capitalizes the first letter', () => {
  assert.strictEqual(capitalize('shop'), 'Shop');
});"
fx_commit "Add text helpers plan and capitalize"
OD="$(dirname "$0")/../../../../bin/overdrive"
"$OD" ledger init --plan docs/plan.md >/dev/null || exit 1
"$OD" ledger add --plan docs/plan.md 'Task 1: complete' || exit 1
"$OD" ledger add --plan docs/plan.md 'Task 2: in-progress' || exit 1
# What the crashed session left behind: an unfinished, uncommitted slugify.
fx_file src/http/text/slugify.js 'function slugify(text) {
  const words = text.trim().toLowerCase().split('"'"' '"'"');'
