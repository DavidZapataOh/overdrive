# Risk map

The risk classifier puts every change in one of three lanes: `direct`, `standard` or `critical`. It decides from facts: the paths a change touches, the lines it adds and removes, and, before any work starts, the text of the request. Two rule files tell it which facts matter:

- **Floors** (`plugins/overdrive/lib/floors.conf`) ship with Overdrive and apply to every project: data and irreversible migrations, auth and tenant isolation, money, secrets, delivery and CI, public contracts, concurrency, dependencies, test harness configuration and the project map itself. Floors cannot be removed by a project.
- **The project map** (`.overdrive/risk-map.conf`) is committed in each project's repository and names what is risky there in particular: a billing module with an unusual name, a domain word in the team's language, an internal API other services consume.

Both files use the grammar below. A change's lane is the highest lane among the items it raises; a change that raises none is `direct`. Besides the rules, the classifier computes five items from the change itself: `test-removed` (critical: a deleted test file, a test renamed to a non-test name, or a test file whose removed test cases outnumber the added ones; an added `describe.skip(`, `it.only(`, `xit(`, `@pytest.mark.skip`, `t.Skip(`, `@Disabled` or `#[ignore]` counts as a removed case unless it replaces a removed one, removing a skipped case gives no credit, and commented-out lines count for nothing), `unscanned-content` (critical: a changed file git shows as binary, through a NUL byte or a `-diff`/`binary` attribute, when its name is not a binary format such as an image, font, archive, media file, PDF, WebAssembly or compiled object), `untested-change` (critical: a changed source file that no test covers, see below), `deletion` (standard: a deleted file that is not a test) and `exec-bit` (standard: an existing file made executable). A `package.json` that adds a `vercel-build`, `deploy`, `release`, `predeploy` or `postdeploy` script raises the critical item `delivery` as well.

### Which tests cover a source

Test files follow the conventions of their runners: `*.test.*`, `*.spec.*`, `*_test.*`, `*_spec.rb`, `test_*.py`, `test_*.rb`, `*Test(s).java`, `*Test(s).kt`, `*Test(s).swift` and `*Test(s).cs` inside a test directory (`src/test/`, `androidTest/`, `Tests/AppTests/`, `Api.Tests/`), anything under `__tests__/`, JVM sources under `src/test/` and Rust files under `tests/`. A changed source file is covered when:

- a test the change carries is named after it and sits in the same package, or sits in its directory (a test in `__tests__/` counts for the directory above); or
- a test in the repository, as of the change's final commit, is named after it and sits in the same directory, in a sibling `__tests__/`, or in its package's test directory (`test/`, `tests/`, `spec/`, `__tests__/` or `src/test/<lang>/` at the package root) at the path that mirrors the source's, with or without the source root (`packages/b/test/util/date.test.ts` covers `packages/b/src/util/date.ts`; `tests/test_models.py` covers `app/models.py`; `src/test/java/x/FooTest.java` covers `src/main/java/x/Foo.java`).

The package is the nearest directory above the file that holds a manifest (`package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `pom.xml`, `build.gradle`, `Package.swift`, `*.csproj` and the like), or the repository root. A test in another package never covers the file, even when it shares its name. A source no test is named after is also covered when a test the change carries imports it, directly or through up to three relative imports (a quoted `./` or `../` path, with or without its extension, or a directory with an `index` file). The imports are read from the files as the change leaves them: the working tree for `--worktree`, the index for `--staged`, the end of the range for `--diff`. A route file that an endpoint test reaches through a shared helper is covered this way; a carried test that imports nothing the change touched covers nothing. Declaration files (`*.d.ts`), tool configuration (`*.config.*`) and the tests themselves need no test.

## Grammar

One rule per line:

```
<kind> <pattern> <item> [lane]
```

- Fields are separated by spaces or tabs.
- Blank lines are ignored. A `#` at the start of a field starts a comment that runs to the end of the line, so comments can stand on their own line or follow a rule.
- `pattern` may be written in double quotes to contain spaces or to start with `#`. Inside quotes, `\"` is a literal quote and `\\` a literal backslash; any other backslash is kept as written, so regular expressions need no extra escaping. Outside quotes a pattern is taken verbatim, quotes and backslashes included. A pattern cannot contain a tab.
- `item` names what the rule detects. It appears in the Risk line (`Risk: critical — money`), so several rules usually share one item. It is lowercase letters and digits joined by single hyphens: `money`, `free-report-admission`.
- `lane` is `critical` (the default) or `standard`. `direct` is not a rule lane: it is what remains when no rule matches.
- CRLF line endings and a UTF-8 byte order mark at the start of the file are accepted, so the file can be edited on any operating system.

## Kinds

| Kind | Pattern | Matches against | Case |
|---|---|---|---|
| `path` | glob | paths the change touches (both sides of a rename) | sensitive (floors: insensitive) |
| `pathtoken` | one path segment token | path segments split on `/ . _ -` | insensitive |
| `keyword` | one or more words | request text and added lines, as whole words | insensitive |
| `symbol` | identifier | added or removed lines, at identifier boundaries | sensitive |
| `content` | extended regular expression | added lines | sensitive |

Lines are read from the change's patch; binary files have none, so their content is never read, and a file of a text format shown as binary raises `unscanned-content` instead of passing unread. A change with unmerged paths (a merge in progress) cannot be classified and is reported `critical`. Documentation files (below) are read only for `content` rules of the item `secrets`: a key pasted into a README is still a leaked key, while SQL quoted in a guide is not a migration. Each item is reported once per file, at its first line.

### path

Globs are relative to the repository root and anchored at both ends. `**` matches any number of characters including `/`, and `**/` matches zero or more whole directories; `*` matches within one segment; `?` matches one character other than `/`. Every other character is literal.

```
path **/migrations/**          data-migration
path packages/db/**            data-migration
path "apps/web/src/app/páginas legales/**"  legal-copy  standard
```

Globs in a project map match case-sensitively, exactly as written. The floors' globs ignore case, because the files they name are spelled differently across tools and platforms (`.Env`, `dockerfile`).

A glob that starts with `/` is rejected, because no repository path starts with one. Use `**/name` to match a file name at any depth, `name` to match it only at the root.

### pathtoken

The token matches a whole segment after splitting the path on `/ . _ -`, ignoring case, or one word of a segment: a segment is also split where a lowercase letter meets an uppercase one, before the last capital of a run of capitals followed by lowercase, and between letters and digits. `pathtoken auth` matches `src/auth/session.ts`, `lib/auth.ts`, `auth.config.json`, `AuthController.ts` and `OAuthToken.ts` (`o`, `auth`, `token`), but not `authors.ts`, `Author.tsx` or `src/billing page/x.ts` (a space does not split). `pathtoken jwt` matches `JWTSecret.ts`; `pathtoken oauth` matches `oauth2/cb.ts`. A token cannot contain any of the separators.

Tokens are not evaluated on documentation files, which describe a subject without being it: `docs/payments.md` is prose, not money code. A documentation file is one whose name ends in `.md`, `.mdx`, `.rst` or `.adoc` (any case), or, under a directory named `docs` or `doc` at any depth, a `.txt`, image or font file; any other file there is code (`docs/.vitepress/config.mts`, `apps/docs/src/pay.ts`), so `src/auth/blocklist.txt` keeps its tokens. Path globs still apply to documentation files, so `path "docs/legal/**" legal` and `.github/workflows/**` match them.

```
pathtoken ledger   money
pathtoken wompi    money
```

### keyword

Keywords match whole words, ignoring case and the accents of Latin letters (`facturación` matches `FACTURACIÓN`, `Facturacion` and the decomposed form macOS writes; `ñ` stays distinct from `n`), in the request text (`overdrive risk --intent`, before work starts) and in added lines (when it runs on the diff). Several words in one keyword match the same words separated by any whitespace. Keywords hold letters, digits and underscores; non-ASCII letters such as `ñ` are allowed.

```
keyword cobro                  money
keyword "reporte gratis"       free-report-admission
```

### symbol

Symbols are identifiers (`[A-Za-z_$][A-Za-z0-9_$]*`) matched at identifier boundaries in added and removed lines, so deleting a call to a guard counts as much as adding one. `symbol requireOrg` matches `requireOrg(ctx)` but not `requireOrgAdmin`.

```
symbol requireOrg        tenant-isolation
symbol organization_id   tenant-isolation
```

### content

Content rules are POSIX extended regular expressions matched against added lines, case-sensitively. To ignore case, bracket each letter: `[Dd][Rr][Oo][Pp][[:space:]]+[Tt][Aa][Bb][Ll][Ee]`.

```
content stripe\.charges\.create     money
content "-----BEGIN [A-Z ]*PRIVATE KEY-----"  secrets
```

Expressions must behave the same in every awk Overdrive runs under (GNU awk, mawk, the BSD awk on macOS, the awk in Git for Windows), so the parser normalizes them:

- Interval expressions are expanded: `[0-9]{3}` becomes `[0-9][0-9][0-9]`, `x{2,}` becomes `xxx*`, `x{1,3}` becomes `xx?x?`. Older awks do not support intervals, and the expansion makes the rule portable without losing precision. Bounds go up to 255 and an expanded pattern up to 4,096 bytes; `{,n}` and other malformed bounds are rejected.
- A brace that does not start an interval is a literal brace and is rewritten as `[{]` or `[}]`.
- Escapes that some awks treat as classes and others as literals (`\d`, `\w`, `\s`, `\b`, `\<`, `\>`: a letter, digit, `<`, `>`, backquote or single quote after a backslash) are rejected. Use bracket expressions (`[0-9]`, `[[:space:]]`) and explicit boundaries (`(^|[^A-Za-z0-9_])word([^A-Za-z0-9_]|$)`) instead.
- Bracket expressions have no escapes in POSIX, and awks disagree on a backslash inside one, so a backslash there is rejected. Put `]` first to match it (`[]a]`, `[^]a]`) and `-` last (`[a-]`). Unknown classes such as `[[:word:]]` and reversed ranges such as `[z-a]` are rejected.
- Unbalanced parentheses, unterminated bracket expressions, empty groups `()`, empty alternatives (`|a`, `a|`, `a||b`, `(|a)`) and a repetition with nothing to repeat (`*a`, `(+a)`, `a|*b`, `a**`) are rejected; some awks accept them and others refuse.
- Finally, every content pattern is compiled once by the awk on the machine. A pattern that awk refuses fails the load like any other invalid rule.

Consumers must use the normalized pattern as data (read from the record stream or the environment), never through `awk -v`, which would process its backslashes a second time.

## Loading

`plugins/overdrive/lib/riskmap.sh` is sourced by Overdrive's scripts and provides `riskmap_load FILE`. On success it prints one record per rule and exits 0:

```
kind<TAB>pattern<TAB>item<TAB>lane<TAB>FILE:line
```

`FILE` is the path exactly as passed. The pattern is normalized: `pathtoken` and `keyword` patterns are lowercased (ASCII), runs of spaces in a keyword become one, and `content` expressions are expanded as described above.

Every invalid line is reported on stderr and the function returns 65 without printing any record, so a map with one broken rule never applies half of its rules:

```
invalid rule at .overdrive/risk-map.conf:12: unknown lane 'high' (critical or standard)
```

A missing or unreadable file returns 66 with `cannot read risk map: FILE`. The classifier treats an invalid project map as a classification failure, which means `critical`.

## Which map applies

The project map is read on every side of the change and the versions are joined: the working tree, the index, `HEAD`, and for `--diff` the range's base and end commits (the merge base for `A...B`). This holds before work starts too (`--intent`, `--paths`), so an uncommitted edit of the map cannot lower a classification. A change that deletes a rule is still judged by it, and one that adds a rule is judged by the new rule too, so editing the map can never lower the change's own lane. Editing `.overdrive/risk-map.conf` is itself the critical item `risk-map`, a floor. Every map read must be valid; one invalid side fails the classification, which then reports `critical`. `--map FILE` replaces the project map entirely, for trying a map out; floors still apply.

## How a project gets its map

The first time Overdrive classifies a change in a repository without `.overdrive/risk-map.conf`, it proposes one. It reads the repository (layout, schema and migration tools, auth and billing code, CI, packages that others consume, the project's instructions and decision log) and writes rules for each floor area as the project actually names it, plus the domain words the team uses, in the team's language. The user reviews the proposal and approves or edits it asynchronously; the approved file is committed like any other change and goes through its own lane. Until a map exists, the floors alone decide. The classifier's note (`risk-map missing; propose one with overdrive:risk-triage`) and the Stop hook ask for the proposal in the first change that finds no map; the proposal file `.overdrive/run/risk-map.proposed` turns later notes into a reminder, so it is proposed once.

The map belongs to the project. Anyone may edit it in a normal change; because `.overdrive/` is part of the repository, every edit is reviewed and versioned with the code it describes.

## How calibration adds rules

When a change was classified too low, for example a billing bug that shipped through `standard`, the correction becomes a rule: the narrowest pattern that would have caught the change (a path, a token, a symbol or an expression) with the item it belongs to. If the project keeps labeled risk cases, the escaped change is added as a case first, so the new rule is proven against it and against the cases that should stay lower. A project rule that fires too often is narrowed, not dropped; the floors stay in place, so calibration can raise a lane but never take a floor away.
