# Closing blocks

Four closes, one per kind of claim. Each ends the closing message; nothing after it restates a claim the block does not support.

## Work you finished, with a stale doc

```
Verified:
- parseDuration accepts "1h30m" and rejects "90x" — npm test: 6 pass, 0 fail (run now, HEAD 3f1c2aa, clean tree)
- parseDuration is exported from src/time.ts — src/time.ts:42
Not verified:
- negative durations — no test covers them; not run
Pending:
- docs/config.md still says durations are whole seconds — update it before the ticket is closed
```

The ticket note that goes with it says the parser and its tests exist and that the config docs are still to be updated. It does not say the docs are updated.

## A fix that did not hold

```
Verified:
- none
Not verified:
- webhook retries stop after 5 attempts — npm test now: 11 pass, 1 fail ("gives up after max attempts": expected 5 calls, got 6, src/webhooks/retry.ts:27)
Pending:
- compare attempts with >= instead of >, rerun npm test — the fix and a green run
```

## A subagent's report

```
Verified:
- db/migrations has no 0043 file; HEAD is "Add invoice table" — ls db/migrations, git log --all
Not verified:
- "0043_add_tax_id migration, applied and rolled back cleanly" — the report says so; no such file, commit or evidence file exists
Pending:
- the migration written or located — the builder, then a migrate and rollback run here
```

The line for the team channel says the migration is not landed and why. It does not repeat "applied and rolled back cleanly".

## An outside fact you could not reach

```
Verified:
- none
Not verified:
- DIAN requires the buyer's email on every electronic invoice — tried: docs/invoicing.md (dated 2024-01, no mention), a search of the repository for "DIAN"; no web access in this session
Pending:
- the current DIAN resolution on electronic invoicing, read at dian.gov.co — before the invoice template ships
```

With the source fetched, the same claim moves to Verified with its URL on the line.
