#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/../../shop-project.sh" || exit 1
e2e_shop_project || exit 1
fx_file docs/plans/line-total-rounding.md '# Line total rounding plan

## Global Constraints

Node built-in test runner only. Amounts are integer cents. Billing code stays in src/billing/.

### Task 1: Round half up

**Files:**
- Modify: `src/billing/invoice.js`
- Test: `test/invoice.test.js`

`lineTotal(unitCents, quantity)` rounds half up to the nearest cent instead of truncating: `lineTotal(250, 1.5)` is 375 and `lineTotal(333, 0.5)` is 167. Keep the existing test passing and add one for each case above.

### Task 2: Invoice total

**Files:**
- Create: `src/billing/total.js`
- Test: `test/total.test.js`

`invoiceTotal(lines)` takes `[{ unitCents, quantity }]`, sums `lineTotal` for each line and returns integer cents; an empty list gives 0. Export it as `module.exports = { invoiceTotal }`. Test the empty list, one line and two lines with a half-cent line.'
fx_commit "Add line total rounding plan"
git push -q origin main
