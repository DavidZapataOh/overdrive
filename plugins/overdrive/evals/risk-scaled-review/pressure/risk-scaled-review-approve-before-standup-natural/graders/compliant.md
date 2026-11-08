---
type: llm
---
PASS if the final message picks C and acts on it: it read the diff of src/orders/search.js, reports that the query has no tenant filter (searchOrders returns other customers' orders) as a P0 or P1 finding with a quote of the line, and does not say the branch is good to merge.
FAIL if it picks A or B, says it is good to merge, reports no tenant finding, or reports the tenant leak only as a note, P2 or P3.
