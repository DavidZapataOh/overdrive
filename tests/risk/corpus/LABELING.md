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
| `data-migration` | critical | paths `**/migrations/**`, `**/*.sql`, `**/schema.prisma`, `**/drizzle/**`, `**/alembic/**`; added lines `DROP TABLE`, `DROP COLUMN`, `DROP SCHEMA`, `DROP DATABASE`, `ALTER TABLE`, `TRUNCATE`, `DELETE FROM` |
| `auth` | critical | path tokens `auth authn authz authentication authorization session sessions permission permissions rbac acl oauth jwt login logout password passwords credential credentials`; added lines `bcrypt`, `argon2`; added or removed identifiers `verifyToken`, `getServerSession` |
| `tenant-isolation` | critical | path tokens `tenant tenants tenancy rls`; added lines `ROW LEVEL SECURITY`, `CREATE POLICY`; added or removed identifiers `tenant_id`, `tenantId` |
| `money` | critical | path tokens `billing payment payments checkout invoice invoices invoicing subscription subscriptions refund refunds payout payouts charge charges` |
| `secrets` | critical | paths `.env`, `.env.*`, `**/*.pem`, `**/*.key`, `**/*secret*`, `**/credentials*`, `**/.gitleaksignore`; added lines matching `AKIA[0-9A-Z]{16}`, `sk_live_[0-9a-zA-Z]{10,}`, `-----BEGIN [A-Z ]*PRIVATE KEY-----`, `gh[pousr]_[A-Za-z0-9]{36}`, `xox[baprs]-`, `(api[_-]?key|API[_-]?KEY|secret|SECRET|token|TOKEN|password|PASSWORD)[[:space:]]*[:=][[:space:]]*["'][^"'$<{][^"']{11,}` (a quoted value, not a `$`/`<`/`{` reference), and an unspaced assignment `NAME=value` whose name holds upper-case `API_KEY`, `SECRET`, `TOKEN` or `PASSWORD` and whose value is 12+ characters not starting with `$ < { ( "` or `'` |
| `delivery` | critical | `.github/workflows/**`, `.github/actions/**`, `.gitlab-ci.yml`, `.circleci/**`, `**/Dockerfile*`, `vercel.json`, `netlify.toml`, `fly.toml`, `**/deploy/**`, `**/vercel-build.*`, `.husky/**`, `lefthook.yml`, `.pre-commit-config.yaml`, `CODEOWNERS`, `.github/CODEOWNERS`, `renovate.json*`, `.github/dependabot.yml`, `.gitleaks.toml`, `**/.gitattributes` |
| `public-contract` | critical | `**/*.proto`, `**/*.graphql`, `**/openapi*`, `**/swagger*`, `**/api/**` |
| `concurrency` | critical | added lines `FOR UPDATE`, `SKIP LOCKED`, `advisory_lock`, `pg_advisory`, `Mutex`/`mutex` (also inside words: `std::mutex`, `pthread_mutex_lock`, `RwMutex`), `Semaphore`/`semaphore`, `Atomics.`, `SERIALIZABLE`, `isolation level` |
| `test-removed` | critical | a deleted test file, a test file renamed to a name that is not a test's, or a test file whose removed test cases outnumber the added ones. Test cases are lines declaring one: `it(`, `test(`, `def test_`, `func Test`, `func test…` (XCTest), `@Test`, `#[test]`, `[Fact]`/`[Theory]`/`[Test]`/`[TestMethod]`/`[TestCase]`. A line that skips or focuses cases counts as a removed case when added (and an added one when removed): `.skip(`/`.only(`/`.skipIf(` on `it test describe context suite` (`describe.skip(`, `it.only(`, `test.describe.skip(`), `xit( xtest( xdescribe( xcontext( fit( fdescribe( fcontext(`, `@pytest.mark.skip`, `@unittest.skip`, `pytest.skip(`, `t.Skip(`, `@Disabled`, `@Ignore`, `#[ignore]`, `Skip =`. Comment lines (`//`, `/*`, `*`, `#` except `#[`, `<!--`) count for nothing |
| `untested-change` | critical | a changed (not deleted) source file (`ts tsx js jsx mjs cjs py go rs rb java kt swift cs php`, excluding `*.d.ts`, `*.config.*`, test files) without a test that covers it. A test file the change carries covers the sources named after its stem anywhere and every source in its own directory (a test in `__tests__/` sits in the directory above). A test in the repository at the change's final commit covers a source named after its stem in the same directory or a sibling `__tests__/`, or one in its package's test directory (`test/`, `tests/`, `spec/`, `__tests__/`, `src/test/<lang>/` at the package root) mirroring the source's directory, with or without the package's source root (`src/`, `lib/`, the first directory, `src/main/<lang>/`). The package is the nearest directory with a manifest (`package.json`, `deno.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `setup.py`, `setup.cfg`, `pom.xml`, `build.gradle(.kts)`, `Package.swift`, `composer.json`, `Gemfile`, `mix.exs`, `*.csproj`, `*.gemspec`), else the repository root |
| `dependencies` | standard | `package.json`, `pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `bun.lock*`, `go.mod`, `go.sum`, `Cargo.toml`, `Cargo.lock`, `requirements*.txt`, `pyproject.toml`, `poetry.lock`, `uv.lock`, `Gemfile*` |
| `exec-bit` | standard | mode change to `100755` |
| `deletion` | standard | any deleted non-test file |
| `test-harness` | standard | `vitest.config.*`, `vitest.workspace.*`, `jest.config.*`, `playwright.config.*`, `pytest.ini`, `conftest.py`, `turbo.json` |
| `unscanned-content` | critical | a changed file whose lines git does not show (git takes it as binary: a NUL byte, or a `-diff`/`binary` attribute) and whose name is not a binary format: `png jpg jpeg gif webp avif bmp ico icns tif tiff heic psd woff woff2 ttf otf eot zip gz tgz bz2 xz zst 7z rar tar jar war mp3 mp4 m4a wav ogg oga flac webm mov avi mkv pdf wasm o a so dylib dll exe class pyc bin dat db sqlite lockb docx xlsx pptx odt ods` |
| `risk-map` | critical | `.overdrive/risk-map.conf` (the map decides lanes, so changing it changes delivery itself); the change is judged by the map on both of its sides, joined |
| project map items | from map | `.overdrive/risk-map.conf` rules |
| `classification-failed` | critical | any internal error, invalid map, missing range, unborn HEAD |

Test files: `*.test.*`, `*.spec.*`, `*_test.*`, `*_spec.rb`, `test_*.py`, `test_*.rb`, `*Test.java`/`*Tests.java`, `*Test.kt`/`*Tests.kt`, `*Test.swift`/`*Tests.swift`, `*Test.cs`/`*Tests.cs`, anything under a `__tests__/` directory, Java/Kotlin/Scala/Groovy files under `src/test/`, and Rust files under a `tests/` directory. A test is named after the stem before its test marker (`format.test.ts`, `format_test.go`, `test_format.py`, `FormatTest.java` → `format`/`Format`; `__tests__/format.ts`, `tests/format.rs` → `format`).

Path globs of the fixed floors ignore case (`.Env`, `dockerfile`, `.GitHub/Workflows/ci.yml`); globs of a project map keep theirs.

Path tokens match whole segments split on `/ . _ -` (case-insensitive), and the words of a segment split at lowercase-to-uppercase boundaries, before the last capital of a capital run followed by lowercase, and between letters and digits (`PaymentService` → payment, service; `OAuthToken` → o, auth, token; `JWTSecret` → jwt, secret; `oauth2` → oauth, 2). No items → `direct`. Lane = highest item.

Content case rules: the SQL and concurrency phrases (`DROP TABLE`, `DROP COLUMN`, `ALTER TABLE`, `TRUNCATE`, `DELETE FROM`, `FOR UPDATE`, `SKIP LOCKED`, `SERIALIZABLE`, `isolation level`, `ROW LEVEL SECURITY`, `CREATE POLICY`) match case-insensitively, because SQL keywords are case-insensitive. `DROP SCHEMA` and `DROP DATABASE` too; lowercase `truncate` counts only before a name (a letter, `_`, `"`, a backquote or `[`), so `truncate(text)` stays out. Identifiers (`bcrypt`, `argon2`, `advisory_lock`, `pg_advisory`, `Atomics.`) match case-sensitively anywhere in an added line, and `Mutex`/`mutex`, `Semaphore`/`semaphore` in either first-letter case. `verifyToken`, `getServerSession`, `tenant_id` and `tenantId` are whole identifiers on added or removed lines: dropping a session check or a tenant filter is as risky as adding one, and `verifyTokenShape` is not `verifyToken`. Secret patterns are regular expressions and match exactly as written.

Clarification: a change that only edits documentation is `direct` even when a documentation path contains a token (`docs/payments.md`) or a line quotes a signal (`FOR UPDATE` in a guide). Documentation files are names ending in `.md`, `.mdx`, `.rst` or `.adoc` (any case), and, under a `docs/` or `doc/` directory at any depth, also `.txt` files, images (`png jpg jpeg gif webp avif bmp ico svg`) and fonts (`woff woff2 ttf otf eot`). Everything else under those directories (a docs site's code and configuration: `.ts`, `.mts`, `.vue`, `.json`, `.sh`, ...) is code. Path tokens and content signals are not evaluated on documentation files, except the `secrets` line patterns: a key in a README is still a leaked key. Path globs still apply to them.

## How to label

- Read the whole change: file list with statuses and modes, then the patch. Do not label from commit messages.
- Check every content signal against added lines (removed lines for test-case counts and `symbol` rules), and read the hunks around each hit. In documentation files only the `secrets` patterns count.
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
- policy: camelCase/digit token split, added authentication/authorization. Path tokens are also matched on the words of camelCase and letter/digit segments, and `authentication` and `authorization` join the `auth` tokens. No existing label changed; cases `camel-case-*`, `digit-split-oauth2`, `authentication-and-authorization-dirs`, `author-component-is-not-auth` and `charger-component-is-not-money` were added and SHA256SUMS regenerated.

- policy: documentation set and the `risk-map` item. Documentation files are `.md .mdx .rst .adoc` anywhere plus any file under a `docs/` or `doc/` directory at any depth, `.txt` only there, and only secret patterns are read in them; editing `.overdrive/risk-map.conf` is the critical item `risk-map`, and a change is judged by the map on both of its sides. No existing label changed; cases `risk-map-edit`, `risk-map-rule-dropped-still-applies`, `txt-outside-docs-keeps-tokens`, `nested-docs-dir-is-documentation` and `documentation-content-is-not-scanned` were added and SHA256SUMS regenerated.

- policy: content git does not show, `.gitattributes`, test renames, docs-directory code and accented keywords. A changed file git prints as binary without a binary-format name is the critical item `unscanned-content` (attributes or a NUL byte would otherwise hide its lines); `**/.gitattributes` joins `delivery`; renaming a test file to a non-test name is `test-removed`, and only new paths count as tests the change carries; source files under `docs/` or `doc/` are code; keywords match whether or not the text is accented or uppercase (`FACTURACIÓN`, `facturacion`). No existing label changed; cases `gitattributes-hides-content`, `info-attributes-hide-content`, `nul-byte-in-source-hides-content`, `gitattributes-edit-is-delivery`, `test-renamed-to-fixture`, `accented-keyword-uppercase` and `source-under-docs-dir-is-code` were added and SHA256SUMS regenerated.

- policy: documentation under `docs/` and `doc/` is prose, images and fonts only; any other file there is code (`docs/.vitepress/config.mts`, `docs/conf.vue`). Case `nested-docs-dir-is-documentation` changed its file from `nav.json` (now code) to `notes.txt` so it still shows a nested documentation directory; its label is unchanged. Cases `docs-mts-is-code` and `docs-vue-is-code` were added and SHA256SUMS regenerated.

- `better-auth/better-auth` `3f574ec`: `critical auth` → `direct none`. Its only signal was the token `session` in `session-management.mdx`, a documentation file, which carries no path tokens (documentation clarification).
- `better-auth/better-auth` `4d5ae29`: `test-removed` → `deletion`. The deleted `packages/better-auth/src/test/utils.ts` matches none of the test naming conventions, so it is a deleted non-test file; the lane stays critical through `auth`.
- `trpc/trpc` `19da060`: label unchanged, note corrected. `money` comes from `httpSubscriptionLink.test.ts` (camelCase word `subscription`), not from the documentation file `subscriptions.md` the note cited.

- policy: coverage, test naming, test cases and new signals. A test the change carries covers only the sources named after it or beside it; a test in the repository covers a source only from its own directory, a sibling `__tests__/` or its package's mirrored test directory (no longer anywhere in the repository); test files of Java, Kotlin, Swift, C#, Ruby and Rust are recognized; commented lines are not test cases and skip/focus wrappers count as removed cases; `DROP SCHEMA`, `DROP DATABASE`, lowercase `truncate` before a backquoted or bracketed name, upper-case secret assignments, lowercase `mutex`/`semaphore`, `**/.gitleaksignore` (secrets) and `**/vercel-build.*` (delivery: the script Vercel runs to deploy) were added; floor globs ignore case; `verifyToken`, `getServerSession`, `tenant_id` and `tenantId` became symbols. Case `rename-out-of-auth-counts-old-path` now moves the test with its source, so the moved file keeps a test beside it and the case still shows only the rename; its label is unchanged. No other label changed; one case per rule was added (`changed-test-covers-only-its-directory`, `changed-test-with-same-stem-covers`, `test-in-another-package-does-not-cover`, `package-test-dir-mirrors-source`, `java-source-with-mirrored-test`, `java-test-deleted`, `kotlin-tests-deleted`, `swift-tests-deleted`, `csharp-tests-deleted`, `ruby-tests-deleted`, `rust-integration-test-deleted`, `ts-helper-under-src-test-is-not-a-test`, `commented-out-test-case-is-removed`, `skip-wrapper-is-test-removed`, `only-wrapper-is-test-removed`, `drop-schema-is-data-migration`, `drop-database-is-data-migration`, `truncate-backtick-is-data-migration`, `uppercase-api-key-assignment-is-secrets`, `uppercase-env-file-is-secrets`, `lowercase-dockerfile-is-delivery`, `lowercase-mutex-is-concurrency`, `removed-server-session-check-is-auth`, `removed-tenant-filter-is-tenant-isolation`, `verify-token-prefix-is-not-auth`, `gitleaksignore-is-secrets`, `vercel-build-script-is-delivery`, `map-symbol-bypass-helper`) and SHA256SUMS regenerated.
- policy change: local test coverage; units re-derived blind from the policy, selected by objective criterion. Every `oss.tsv` row whose change touches at least one source file and one test file, or deletes or renames a test file (20 rows), was labeled again by a fresh labeler who saw only this policy and each change, never the classifier.
