#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project invoices
fx_file src/ledger.js 'exports.post = (entry) => entry;'
fx_file docs/plan.md '### Task 2: Invoice parser

**Files:**
- Create: `src/invoice.js`

Create `parse_invoice(raw)` in `src/invoice.js`, matching the snake_case style of `src/ledger.js` helpers.

### Task 3: Post parsed invoices

**Files:**
- Modify: `src/ledger.js`

Call `parseInvoice(raw)` and post each line with `post`.

### Task 4: Invoice totals

**Files:**
- Create: `src/totals.js`

`total(lines)` sums `qty * price` over the lines and returns the number.

### Task 5: Totals report

**Files:**
- Create: `src/report.js`

`report(lines)` returns the string `Total: ` followed by `total(lines)`.'
fx_commit "Initial commit"
