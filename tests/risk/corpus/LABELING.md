# Risk labeling instructions

These labels are the ground truth for the deterministic risk classifier. They are written from the policy below and from each change alone, never from classifier code, and are frozen once written.

## Lanes

| Lane | When | Plan | TDD | Execution | Review |
|---|---|---|---|---|---|
| **Direct** | Understood in one reading pass, no risk items, resumable from the request + `git diff` | None | If something is testable: test first | The main agent, inline | None of its own; verification with evidence |
| **Standard** | Neither direct nor critical | Short decision plan | Mandatory where it applies | Inline, or one builder agent (Sonnet) per task | One review at the end of the slice (Sonnet), per surface |
| **Critical** | Touches a fixed floor, or the project's risk map marks it | Full TDD plan; the user approves the plan before building | Mandatory, with hard cases, real (real database, etc.) and a non-regression test against the previous code | One agent per task, in order | Per-task review (Opus) + final review of the slice (Opus) |

**Fixed floors (always critical):** irreversible data and migrations; authentication/authorization and isolation between customers; money and charges; secrets and credentials; security and the CI/delivery itself; public contracts that others consume (API, schemas); concurrency; changes without any test that would catch a regression.

**The risk line:** every change closes with `Risk: <lane> — <items | none>`. Skipping the process stays visible.

**The user can raise the lane** of anything ("treat it as critical"). To lower it on something that touches a fixed floor, the framework warns about the risk and asks for explicit confirmation.

## Items and signals

| Item | Lane | Signals |
|---|---|---|
| `data-migration` | critical | paths `**/migrations/**`, `**/*.sql`, `**/schema.prisma`, `**/drizzle/**`, `**/alembic/**`; added lines `DROP TABLE`, `DROP COLUMN`, `ALTER TABLE`, `TRUNCATE`, `DELETE FROM` |
| `auth` | critical | path tokens `auth authn authz session sessions permission permissions rbac acl oauth jwt login logout password passwords credential credentials`; added lines `bcrypt`, `argon2`, `verifyToken`, `getServerSession` |
| `tenant-isolation` | critical | path tokens `tenant tenants tenancy rls`; added lines `ROW LEVEL SECURITY`, `CREATE POLICY`, `tenant_id`, `tenantId` |
| `money` | critical | path tokens `billing payment payments checkout invoice invoices invoicing subscription subscriptions refund refunds payout payouts charge charges` |
| `secrets` | critical | paths `.env`, `.env.*`, `**/*.pem`, `**/*.key`, `**/*secret*`, `**/credentials*`; added lines matching `AKIA[0-9A-Z]{16}`, `sk_live_[0-9a-zA-Z]{10,}`, `-----BEGIN [A-Z ]*PRIVATE KEY-----`, `gh[pousr]_[A-Za-z0-9]{36}`, `xox[baprs]-`, `(api[_-]?key|secret|token|password)[[:space:]]*[:=][[:space:]]*["'][^"']{12,}` |
| `delivery` | critical | `.github/workflows/**`, `.github/actions/**`, `.gitlab-ci.yml`, `.circleci/**`, `**/Dockerfile*`, `vercel.json`, `netlify.toml`, `fly.toml`, `**/deploy/**`, `.husky/**`, `lefthook.yml`, `.pre-commit-config.yaml`, `CODEOWNERS`, `.github/CODEOWNERS`, `renovate.json*`, `.github/dependabot.yml`, `.gitleaks.toml` |
| `public-contract` | critical | `**/*.proto`, `**/*.graphql`, `**/openapi*`, `**/swagger*`, `**/api/**` |
| `concurrency` | critical | added lines `FOR UPDATE`, `SKIP LOCKED`, `advisory_lock`, `pg_advisory`, `Mutex`, `Semaphore`, `Atomics.`, `SERIALIZABLE`, `isolation level` |
| `test-removed` | critical | a deleted test file, or a test file whose removed `it(`/`test(`/`def test_`/`func Test` lines outnumber added ones |
| `untested-change` | critical | a changed (not deleted) source file (`ts tsx js jsx mjs cjs py go rs rb java kt swift cs php`, excluding `*.d.ts`, `*.config.*`, test files) when the diff changes no test file and the repo has no test named after its stem (`stem.test.*`, `stem.spec.*`, `test_stem.py`, `stem_test.*`, `__tests__/stem.*`) |
| `dependencies` | standard | `package.json`, `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lock*`, `go.mod`, `go.sum`, `Cargo.toml`, `Cargo.lock`, `requirements*.txt`, `pyproject.toml`, `poetry.lock`, `uv.lock`, `Gemfile*` |
| `exec-bit` | standard | mode change to `100755` |
| `deletion` | standard | any deleted non-test file |
| `test-harness` | standard | `vitest.config.*`, `vitest.workspace.*`, `jest.config.*`, `playwright.config.*`, `pytest.ini`, `conftest.py`, `turbo.json` |
| project map items | from map | `.overdrive/risk-map.conf` rules |
| `classification-failed` | critical | any internal error, invalid map, missing range, unborn HEAD |

Path tokens match whole segments split on `/ . _ -` (case-insensitive). No items → `direct`. Lane = highest item.

Content case rules: the SQL and concurrency phrases (`DROP TABLE`, `DROP COLUMN`, `ALTER TABLE`, `TRUNCATE`, `DELETE FROM`, `FOR UPDATE`, `SKIP LOCKED`, `SERIALIZABLE`, `isolation level`, `ROW LEVEL SECURITY`, `CREATE POLICY`) match case-insensitively, because SQL keywords are case-insensitive. Identifiers (`bcrypt`, `argon2`, `verifyToken`, `getServerSession`, `tenant_id`, `tenantId`, `advisory_lock`, `pg_advisory`, `Mutex`, `Semaphore`, `Atomics.`) match case-sensitively, as written. Secret patterns are regular expressions and match exactly as written.

Clarification: a change that only edits documentation is `direct` even when a documentation path contains a token (`docs/payments.md`); path tokens are not evaluated on documentation files (`*.md`, `*.mdx`, `*.rst`, `*.adoc`). Path globs and content signals still apply to them.

## How to label

- Read the whole change: file list with statuses and modes, then the patch. Do not label from commit messages.
- Check every content signal against added lines (removed lines for test-case counts and map `symbol` rules), and read the hunks around each hit.
- Apply the table literally: an item applies when its signal is present. Never drop an item whose signal is present, even if it looks harmless; record the disagreement in the note as `policy-doubt: …`.
- When a change plainly touches a fixed floor that no signal catches (for example, an authorization check in a file without an auth path token), add the floor item and explain it in the note as `judgment: …`.
- `untested-change` looks at the test files present at the change's final commit, not only at the diff.
- Items are comma-separated and sorted, or `none`. The lane is the highest lane among the items.

## Corpora

### Synthetic (`synthetic/<case>/`)

Each case is authored together with its label:

- `setup.sh` builds the baseline in an empty repository; the runner commits it.
- `risk-map.conf`, when present, is committed with the baseline as `.overdrive/risk-map.conf`.
- `change.sh` makes the change on top of the baseline without committing it.
- `expected` holds `lane <lane>` and `items <a,b|none>`.

The classifier runs in `--worktree` mode (tracked changes against `HEAD` plus untracked files), so cases can add, edit, delete, rename and change modes freely. Strings that look like real secrets are assembled at run time inside `change.sh`; the repository never contains them.

### OSS (`oss.tsv`)

`repo<TAB>sha<TAB>lane<TAB>items<TAB>note`, one row per commit of `vercel/next.js`, `trpc/trpc`, `better-auth/better-auth` and `medusajs/medusa`. Rows were labeled blind by a fresh agent that saw only this policy and each commit's `git show --stat --patch` output. The runner classifies `sha^..sha`, `sha^1..sha` for a merge, and the empty tree against `sha` for a root commit, on bare partial clones (`--filter=blob:none`).

## Running

```
bash tests/risk/run-corpus.sh --synthetic tests/risk/corpus/synthetic
bash tests/risk/run-corpus.sh --tsv tests/risk/corpus/oss.tsv --clone-cache DIR
```

`OVERDRIVE_BIN` selects the classifier (default `plugins/overdrive/bin/overdrive`). The clone cache may start empty; missing repositories and commits are fetched.

## Freezing and relabeling

`SHA256SUMS` holds the SHA-256 of every file under `synthetic/` and of `oss.tsv`; the runner refuses to run when any of them differs or a case is not listed. Labels are never changed to make the classifier pass. A relabel is a deliberate commit that edits the label, regenerates the sums and adds a line below with the reason:

```
cd tests/risk/corpus && find synthetic oss.tsv -type f | LC_ALL=C sort | xargs sha256sum > SHA256SUMS
```

### Relabel log

- `lowercase-prose-is-not-concurrency` replaced by `update-form-prose-is-not-concurrency`, and `lowercase-for-update-is-concurrency` and `truncate-lowercase-is-data-migration` added: SQL and concurrency phrases match case-insensitively, so lowercase `for update` in prose is no longer a valid negative.

### Pending conflicts

These `oss.tsv` rows are critical only through a path token in a documentation file, which contradicts the documentation clarification above. They will be relabeled deliberately during calibration:

- `better-auth/better-auth` `3f574ec70bb15c155a78673d42c5e25f7376ced3` (`auth` from `session-management.mdx`).
- `trpc/trpc` `19da060cb0e05c75682ec813c606b51c6c52ee19` (`money` from `subscriptions.md`; `public-contract` is a judgment item).
