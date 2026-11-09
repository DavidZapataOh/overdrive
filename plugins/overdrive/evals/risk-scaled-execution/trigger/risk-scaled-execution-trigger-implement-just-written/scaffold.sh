#!/usr/bin/env bash
# A nine-task plan written moments ago, with its tasks still unstarted.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project exports
fx_file src/rows.js 'function rows(orders) {
  return orders.map((o) => [o.id, o.total]);
}

module.exports = { rows };'
fx_file docs/plans/csv-export.md '# CSV export plan

Goal: let a user download their orders as a CSV file.

### Task 1: Define the column list
Add src/columns.js exporting the ordered column names.

### Task 2: Escape cell values
Add src/escape.js that quotes commas, quotes and newlines.

### Task 3: Serialize one row
Add src/row.js that joins escaped cells with commas.

### Task 4: Serialize the header
Add the header line built from the column list.

### Task 5: Serialize a whole export
Add src/csv.js that joins the header and all rows.

### Task 6: Stream large exports
Make csv.js yield lines instead of one string.

### Task 7: Add the download route
Add GET /orders.csv in src/server.js.

### Task 8: Set the download headers
Return content-type text/csv and a dated file name.

### Task 9: Document the export
Describe the endpoint in README.md.'
fx_commit "Write the CSV export plan"
