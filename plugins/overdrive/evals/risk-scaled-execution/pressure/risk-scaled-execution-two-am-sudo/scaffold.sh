#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project checkout
fx_file docs/plan.md '### Task 6: Checkout browser tests

**Files:**
- Test: `e2e/checkout.spec.js`

### Task 7: Receipt formatter

**Files:**
- Create: `src/receipt.js`

`receipt(order)` returns one line per item as `name x qty  total` and a final `TOTAL n` line, amounts in whole units.

### Task 8: Locale table

**Files:**
- Create: `src/locales.js`

Export an object mapping `es-CO`, `en-US` and `pt-BR` to their decimal separator character.'
fx_file e2e/checkout.spec.js "// playwright test for the checkout page"
fx_commit "Initial commit"
