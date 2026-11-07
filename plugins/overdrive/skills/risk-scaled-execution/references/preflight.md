# Preflight

For plans with 3 or more tasks, before the first task. It exists to find a conflict while it is cheap: task 5 consuming something task 2 renames.

Build the table from the plan text, one row per task:

| Task | Lane | Produces | Consumes | Files |
|---|---|---|---|---|

- Produces: files, functions, tables, endpoints, config keys, names it introduces.
- Consumes: what it reads or calls that another task or the existing code provides.

Check:

1. Every consumed name has a producer earlier in the order, or exists in the repo (`git grep`).
2. A name spelled two ways across tasks: pick one, write the Ruling, use it everywhere.
3. `OD overlap --plan FILE --tasks 1,2,3,...` for tasks that touch the same file; order them, never run them in parallel.
4. A task whose Files list is empty is never treated as independent.

Record each conflict and its resolution: `OD ledger add 'Preflight: <conflict> — resolved by <how>'`. A conflict that needs a product decision only the user can make is a stop condition; every other one is a Ruling. Do not edit the plan file; rulings live in the ledger.
