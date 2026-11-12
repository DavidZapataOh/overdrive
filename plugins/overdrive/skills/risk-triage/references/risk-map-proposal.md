# Proposing a project risk map

The floors know generic names (`billing`, `auth`, `migrations`). A project names its risky code its own way: a payments package called after the provider, permissions in Spanish, a tenant key called `org_id`. The map (`.overdrive/risk-map.conf`, one rule per line: `<kind> <pattern> <item> [critical|standard]`, critical by default, so write `standard` on any rule whose files are risky to review but cannot lose data or money; `#` comments) teaches the classifier those names. Propose it once per repository, when the classifier prints `note risk-map missing; propose one with overdrive:risk-triage`.

## Steps

1. **Read the repository's own description**: `CLAUDE.md`, `README*`, `CONTRIBUTING*`, `.overdrive/decisions.md`, the manifests, and the layout (`git ls-files | cut -d/ -f1-3 | sort -u`). Note the language the team writes in.
2. **Find each floor area as this project names it**: data (migrations, schema, seeds, data scripts), auth (sessions, roles, permissions), tenancy (the per-customer key: `org_id`, `company_id`, `empresa_id`), money (billing, payment providers, ledgers, invoices, prices), secrets (key files, env loaders), delivery (CI, deploy and infra scripts), public contracts (packages others import, API schemas, webhooks), concurrency (queues, locks, schedulers).
3. **Propose only what the repository shows.** A rule needs evidence in the files read in step 1: a package that handles money, a tenant key, a migrations folder under an unusual name. An area the repository never mentions gets no rule. Lint, formatter, type-check, bundler and task-runner configuration (`eslint.config.js`, `tsconfig.json`, `turbo.json`, `vite.config.*`) is not a floor: the floors already put `turbo.json` at standard and the rest at direct, and a rule must not raise it. `delivery` is the pipeline that ships (CI, deploy, release); `data-migration` is code that rewrites stored data, not a seed script that only reads or fills a development database.
4. **Keep only the gaps.** Run `overdrive risk --paths <one representative file per area>`. An area whose files the floors already mark with the right item needs no rule.
5. **Write the narrowest rule for each gap**, with the floor's item name so the Risk line reads the same everywhere:

   | What the project has | Rule |
   | --- | --- |
   | a directory or file | `path <glob> <item>` |
   | a word inside file names | `pathtoken <word> <item>` |
   | a domain word in the team's language | `keyword <word> <item>` (accents are ignored) |
   | a guard function or tenant key | `symbol <identifier> <item>` |
   | a code pattern | `content <extended regex> <item>` |

6. **Prove every rule fires.** Save the proposal to `.overdrive/run/risk-map.proposed` with the Write tool (the run directory ignores itself; a sandboxed shell may not write there), then run `overdrive risk --map .overdrive/run/risk-map.proposed --paths <one file per rule>`; each rule's item must appear. Take the files from the repository's existing layout, not from the change you are making: the proposal is a question for the user and never classifies this request, which keeps the lane the floors gave it. Fix any rule the loader rejects.
7. **Show it in the reply**, one rule per line with a comment saying what it protects, and ask for approval:

   ```
   # Proposed .overdrive/risk-map.conf
   path    services/ledgerd/**      money              # all charges and refunds go through it
   keyword cobro                    money              # the team's word for a charge
   path    src/acceso/**            auth               # roles and permissions
   symbol  org_id                   tenant-isolation   # every query filters by it
   path    infra/**                 delivery           # deploy scripts
   ```

   Then: "Approve or edit it and I will commit it as `.overdrive/risk-map.conf` in its own change (critical: `risk-map`)."
8. **Do not write `.overdrive/risk-map.conf` before the approval**, and do not hold the user's request for it: the request goes on in its own lane under the floors.

## Once

`.overdrive/run/risk-map.proposed` marks the proposal as made: while it exists and the map does not, the classifier's note says `risk-map missing; a proposal waits for approval in .overdrive/run/risk-map.proposed`, and a reply mentions it in one line instead of proposing again. After the approval, commit the map as its own change; it is classified critical (`risk-map`) like any edit of the map.
