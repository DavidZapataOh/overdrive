#!/usr/bin/env bash
# Tests for overdrive risk: content, intent and computed signals.
# shellcheck disable=SC2016  # fixture lines hold literal backquotes and dollar signs

# shellcheck source=helpers.sh
. "$(dirname "$RUNNER")/risk/helpers.sh"

# A repository whose baseline holds src/app.ts and its test, so appended lines are
# judged by content alone.
content_repo() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/app.ts
  commit_all "$repo" base
  printf '%s\n' "$repo"
}

test_secret_in_added_line_is_critical() {
  local repo key
  repo=$(content_repo)
  # Assembled here so the repository never holds a string that looks like a live key.
  key="sk""_live_$(printf 'Zq%.0s' 1 2 3 4 5 6 7 8)"
  printf 'const stripe = "%s";\n' "$key" >> "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "item secrets critical floor line src/app.ts:2"
  assert_eq "Risk: critical — secrets" "$(risk_line)"

  # Documentation is not scanned for content, except for secrets.
  git -C "$repo" checkout -q -- src/app.ts
  printf 'Use `%s` and FOR UPDATE.\n' "$key" > "$repo/README.md"
  risk "$repo" --worktree
  assert_line "$out" "item secrets critical floor line README.md:1"
  assert_no_line "$out" "concurrency"

  git -C "$repo" add README.md
  risk "$repo" --staged
  assert_line "$out" "item secrets critical floor line README.md:1"
  git -C "$repo" commit -q -m readme
  risk "$repo" --diff HEAD~1..HEAD
  assert_line "$out" "item secrets critical floor line README.md:1"

  # Removed secrets are not added secrets.
  git -C "$repo" rm -q README.md
  risk "$repo" --staged
  assert_no_line "$out" "secrets"
}

test_binary_content_is_never_scanned() {
  local repo key
  repo=$(content_repo)
  key="AK""IA$(printf 'Q7X2M4P9R3T6V8W1')"
  printf '\000%s FOR UPDATE\n' "$key" > "$repo/src/blob.dat"
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
  git -C "$repo" add src/blob.dat
  risk "$repo" --staged
  assert_line "$out" "lane direct"
}

test_migration_drop_is_critical() {
  local repo
  repo=$(content_repo)
  printf 'await db.execute("drop table users");\nexport const dropTables = 1;\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_line "$out" "item data-migration critical floor line src/app.ts:2"
  assert_no_line "$out" "src/app.ts:3"
  assert_eq "Risk: critical — data-migration" "$(risk_line)"
}

test_concurrency_keyword_in_added_line() {
  local repo
  repo=$(content_repo)
  printf 'const a = 1;\nconst q = sql`select * from jobs for update skip locked`;\n' >> "$repo/src/app.ts"
  write_file "$repo" src/lock.go 'var mu sync.Mutex'
  write_file "$repo" src/lock_test.go 'func TestLock(t *testing.T) {}'
  risk "$repo" --worktree
  assert_line "$out" "item concurrency critical floor line src/app.ts:3"
  assert_line "$out" "item concurrency critical floor line src/lock.go:1"
  # One evidence line per item and file, however many lines match.
  assert_eq 1 "$(printf '%s\n' "$out" | grep -c 'concurrency critical floor line src/app.ts')"
  assert_eq "Risk: critical — concurrency" "$(risk_line)"
  # Prose that only shares a word is not concurrency.
  git -C "$repo" checkout -q -- src/app.ts
  rm "$repo/src/lock.go" "$repo/src/lock_test.go"
  printf '// update form for the profile\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
}

test_removed_test_cases_are_critical() {
  local repo
  repo=$(make_repo)
  write_file "$repo" src/math.ts 'export const add = 1;'
  printf 'it("a", () => {});\nit("b", () => {});\ntest("c", () => {});\n' > "$repo/src/math.test.ts"
  write_file "$repo" tests/test_slug.py 'def test_a():
    pass'
  commit_all "$repo" base
  printf 'it("a", () => {});\nit("b and c", () => {});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_line "$out" "item test-removed critical computed path src/math.test.ts"
  assert_eq "Risk: critical — test-removed" "$(risk_line)"

  # Rewriting cases one for one removes nothing.
  printf 'it("a", () => {});\nit("b", () => {});\ntest("c2", () => {});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_line "$out" "lane direct"

  # Deleting a test file removes its tests, whatever it holds.
  git -C "$repo" checkout -q -- src/math.test.ts
  git -C "$repo" rm -q tests/test_slug.py
  risk "$repo" --staged
  assert_line "$out" "item test-removed critical computed path tests/test_slug.py"
  assert_no_line "$out" "^item deletion "
  assert_eq 1 "$(printf '%s\n' "$out" | grep -c '^item test-removed ')"
}

test_untested_source_change_is_critical() {
  local repo
  repo=$(make_repo)
  write_file "$repo" src/format.ts 'export const f = 1;'
  write_file "$repo" src/types.d.ts 'export type T = 1;'
  write_file "$repo" vite.config.ts 'export default {};'
  write_file "$repo" src/old.py 'x = 1'
  commit_all "$repo" base
  printf 'export const g = 2;\n' >> "$repo/src/format.ts"
  printf 'export type U = 2;\n' >> "$repo/src/types.d.ts"
  printf '// base\n' >> "$repo/vite.config.ts"
  git -C "$repo" rm -q src/old.py
  write_file "$repo" lib/slug.py 'def slug(s): return s'
  risk "$repo" --worktree
  assert_line "$out" "item untested-change critical computed path src/format.ts"
  assert_line "$out" "item untested-change critical computed path lib/slug.py"
  assert_no_line "$out" "untested-change .* (src/types.d.ts|vite.config.ts|src/old.py)$"

  # A test the change carries covers the sources beside it or named after it, no others.
  write_file "$repo" src/other.test.ts 'test("o", () => {});'
  risk "$repo" --worktree
  assert_no_line "$out" "untested-change .* src/format.ts$"
  assert_line "$out" "item untested-change critical computed path lib/slug.py"
  write_file "$repo" tests/slug_test.py 'def test_s(): pass'
  risk "$repo" --worktree
  assert_no_line "$out" "untested-change"
}

test_source_change_with_sibling_test_is_not_untested() {
  local repo bare
  repo=$(make_repo)
  write_file "$repo" src/format.ts 'export const f = 1;'
  write_file "$repo" test/format.spec.ts 'it("f", () => {});'
  write_file "$repo" pkg/calc/calc.go 'package calc'
  write_file "$repo" pkg/calc/calc_test.go 'package calc'
  write_file "$repo" lib/slug.py 'x = 1'
  write_file "$repo" tests/test_slug.py 'def test_slug(): pass'
  write_file "$repo" src/parse.js 'module.exports = 1;'
  write_file "$repo" src/__tests__/parse.js 'test("p", () => {});'
  write_file "$repo" src/lonely.ts 'export const l = 1;'
  commit_all "$repo" base
  printf '// more\n' >> "$repo/src/format.ts"
  printf '// more\n' >> "$repo/pkg/calc/calc.go"
  printf '# more\n' >> "$repo/lib/slug.py"
  printf '// more\n' >> "$repo/src/parse.js"
  printf '// more\n' >> "$repo/src/lonely.ts"
  risk "$repo" --worktree
  assert_eq "Risk: critical — untested-change" "$(risk_line)"
  assert_line "$out" "item untested-change critical computed path src/lonely.ts"
  assert_eq 1 "$(printf '%s\n' "$out" | grep -c '^item ')"
  git -C "$repo" add -A
  risk "$repo" --staged
  assert_eq 1 "$(printf '%s\n' "$out" | grep -c '^item untested-change ')"
  git -C "$repo" commit -q -m more

  # --diff looks for tests in the range's end commit, also in a bare repository.
  git -C "$repo" rm -q test/format.spec.ts
  git -C "$repo" commit -q -m drop-test
  printf '// again\n' >> "$repo/src/format.ts"
  git -C "$repo" commit -q -am again
  bare=$PWD/bare.git
  git clone -q --bare "$repo" "$bare"
  risk "$bare" --diff HEAD~2..HEAD~1
  assert_line "$out" "item test-removed critical computed path test/format.spec.ts"
  risk "$bare" --diff HEAD~1..HEAD
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item untested-change critical computed path src/format.ts"
  risk "$bare" --diff HEAD~3..HEAD~2
  assert_no_line "$out" "path src/format.ts$"
}

test_intent_keyword_from_map() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'keyword cobro money
keyword "reporte gratis" free-report standard'
  commit_all "$repo" map
  risk "$repo" --intent "ajusta el cobro"
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" 'item money critical map keyword "cobro"'
  assert_eq "Risk: critical — money" "$(risk_line)"
  # Whole words, any case, any whitespace between the words of a keyword.
  risk "$repo" --intent "Ajusta los COBROS y el Reporte
  Gratis"
  assert_no_line "$out" "^item money "
  assert_line "$out" 'item free-report standard map keyword "reporte gratis"'
  # Added lines are read the same way.
  source_with_test "$repo" src/fees.ts
  commit_all "$repo" fees
  printf '// Cobro mensual\n' >> "$repo/src/fees.ts"
  risk "$repo" --worktree
  assert_line "$out" "item money critical map line src/fees.ts:2"
}

test_intent_alone_uses_paths_given() {
  local repo
  repo=$(make_repo)
  risk "$repo" --intent "rename the label"
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "lane direct"
  assert_no_line "$out" "^note intent"
  risk "$repo" --intent "rename the label" --paths src/auth/label.ts docs/x.md
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "item auth critical floor path src/auth/label.ts"
  # Named paths are plans, not changes: nothing is computed from them.
  assert_no_line "$out" "untested-change"
  assert_eq "Risk: critical — auth" "$(risk_line)"
}

test_symbol_on_added_or_removed_lines() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'symbol requireOrg tenant-isolation
symbol $scope scoping standard'
  source_with_test "$repo" src/routes.ts
  printf 'requireOrg(ctx);\nrequireOrgAdmin(ctx);\n' >> "$repo/src/routes.ts"
  commit_all "$repo" base
  printf 'export const x = 1;\nrequireOrgAdmin(ctx);\n' > "$repo/src/routes.ts"
  risk "$repo" --worktree
  assert_line "$out" "item tenant-isolation critical map line src/routes.ts:2"
  printf 'requireOrgAdmin(ctx);\nconst y = a.$scope;\n' >> "$repo/src/routes.ts"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m swap
  risk "$repo" --diff HEAD~1..HEAD
  assert_line "$out" "item scoping standard map line src/routes.ts:4"
  printf 'export const requireOrgAdminX = 1;\n' > "$repo/src/routes.ts"
  git -C "$repo" commit -q -am again
  printf 'requireOrgAdmin2(ctx);\n' > "$repo/src/routes.ts"
  risk "$repo" --worktree
  assert_no_line "$out" "tenant-isolation"
}

test_content_rule_from_map() {
  local repo
  repo=$(content_repo)
  write_file "$repo" .overdrive/risk-map.conf 'content "stripe\.charges\.create" money'
  commit_all "$repo" map
  printf 'await stripe.charges.create({});\nstripeXchargesXcreate();\n' >> "$repo/src/app.ts"
  write_file "$repo" docs/howto.md 'stripe.charges.create'
  risk "$repo" --worktree
  assert_line "$out" "item money critical map line src/app.ts:2"
  assert_no_line "$out" "docs/howto.md"
}

test_untracked_files_are_scanned_but_ignored_ones_are_not() {
  local repo
  repo=$(content_repo)
  write_file "$repo" .gitignore 'ignored/'
  commit_all "$repo" ignore
  write_file "$repo" 'src/new dir/jobs é.ts' 'const m = new Mutex();'
  write_file "$repo" 'src/new dir/jobs é.test.ts' 'test("j", () => {});'
  write_file "$repo" ignored/x.ts 'const m = new Mutex();'
  risk "$repo" --worktree
  assert_line "$out" "item concurrency critical floor line src/new dir/jobs é.ts:1"
  assert_no_line "$out" "ignored/"
  # The real index is left as it was.
  assert_eq "" "$(git -C "$repo" diff --cached --name-only)"
  assert_eq "" "$(git -C "$repo" ls-files -- 'src/new dir')"
}

# hidden_or_read ITEM_LINE: the file's content was either read (ITEM_LINE is reported) or
# hidden from the patch and reported as unscanned. Git versions differ on whether a -diff
# attribute hides a file's lines in every mode; either way nothing passes unread.
hidden_or_read() {
  if ! printf '%s\n' "$out" | grep -qxF "item unscanned-content critical computed path src/app.ts"; then
    assert_line "$out" "$1"
  fi
  assert_no_line "$out" "^lane (direct|standard)$"
}

test_text_marked_binary_is_unscanned_content() {
  local repo bare
  repo=$(content_repo)
  # Git prints no lines for a file it takes as binary, so its content cannot be judged.
  printf '*.ts -diff\n' > "$repo/.gitattributes"
  commit_all "$repo" attributes
  printf 'const m = new Mutex();\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  hidden_or_read "item concurrency critical floor line src/app.ts:2"
  git -C "$repo" commit -q -am mutex
  bare=$PWD/bare.git
  git clone -q --bare "$repo" "$bare"
  risk "$bare" --diff HEAD~1..HEAD
  hidden_or_read "item concurrency critical floor line src/app.ts:2"

  # Attributes from .git/info/attributes hide content the same way.
  git -C "$repo" rm -q .gitattributes
  git -C "$repo" commit -q -m no-attributes
  printf '* -diff\n' > "$repo/.git/info/attributes"
  printf 'DROP TABLE users;\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  hidden_or_read "item data-migration critical floor line src/app.ts:3"
  rm "$repo/.git/info/attributes"

  # A NUL byte makes every git take a source file as binary.
  git -C "$repo" checkout -q -- src/app.ts
  printf 'const k = 1;\000\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_line "$out" "item unscanned-content critical computed path src/app.ts"
  assert_eq "Risk: critical — unscanned-content" "$(risk_line)"

  # Known binary formats are not content to read.
  git -C "$repo" checkout -q -- src/app.ts
  printf '\211PNG\000\001' > "$repo/src/logo.png"
  printf '\000\001' > "$repo/src/font.woff2"
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
}

test_gitattributes_change_is_delivery() {
  local repo
  repo=$(content_repo)
  printf '*.ts -diff\n' > "$repo/.gitattributes"
  write_file "$repo" packages/web/.gitattributes '*.sql binary'
  risk "$repo" --worktree
  assert_line "$out" "item delivery critical floor path .gitattributes"
  assert_line "$out" "item delivery critical floor path packages/web/.gitattributes"
}

test_rename_of_a_test_to_a_non_test_removes_it() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/a.ts
  commit_all "$repo" base
  git -C "$repo" mv src/a.test.ts src/a.fixture.ts
  printf 'export const y = 2;\n' >> "$repo/src/a.ts"
  risk "$repo" --worktree
  assert_line "$out" "item test-removed critical computed path src/a.test.ts"
  # The old test path no longer counts as a test the change carries.
  assert_line "$out" "item untested-change critical computed path src/a.ts"
}

test_accented_keyword_matches_any_case_and_form() {
  local repo nfd
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'keyword facturación billing'
  commit_all "$repo" map
  for text in "ajusta la FACTURACIÓN" "Facturación mensual" "sin acento: facturacion"; do
    risk "$repo" --intent "$text"
    assert_line "$out" 'item billing critical map keyword "facturación"'
  done
  # Decomposed form (o followed by a combining acute accent), as macOS file names use.
  nfd=$(printf 'FACTURACIO\314\201N')
  risk "$repo" --intent "$nfd"
  assert_line "$out" 'item billing critical map keyword "facturación"'
  risk "$repo" --intent "facturaciones"
  assert_no_line "$out" "^item billing"
  source_with_test "$repo" src/fees.ts
  commit_all "$repo" fees
  printf '// FACTURACIÓN mensual\n' >> "$repo/src/fees.ts"
  risk "$repo" --worktree
  assert_line "$out" "item billing critical map line src/fees.ts:2"
}

test_source_under_a_docs_directory_is_code() {
  local repo
  repo=$(make_repo)
  write_file "$repo" apps/docs/src/billing/pay.ts 'const m = new Mutex();'
  write_file "$repo" apps/docs/src/billing/pay.test.ts 'test("p", () => {});'
  write_file "$repo" apps/docs/billing/guide.mdx 'FOR UPDATE'
  risk "$repo" --worktree
  assert_line "$out" "item concurrency critical floor line apps/docs/src/billing/pay.ts:1"
  assert_line "$out" "item money critical floor path apps/docs/src/billing/pay.ts"
  assert_no_line "$out" "guide.mdx"
}

test_any_code_under_a_docs_directory_is_code() {
  local repo f
  repo=$(make_repo)
  for f in apps/docs/src/billing/pay.mts docs/.vitepress/config.mts docs/run.sh docs/conf.vue; do
    write_file "$repo" "$f" 'const m = new Mutex();'
  done
  risk "$repo" --worktree
  for f in apps/docs/src/billing/pay.mts docs/.vitepress/config.mts docs/run.sh docs/conf.vue; do
    assert_line "$out" "item concurrency critical floor line $f:1"
  done
  assert_line "$out" "item money critical floor path apps/docs/src/billing/pay.mts"
}

test_drop_schema_and_database_are_data_migration() {
  local repo
  repo=$(content_repo)
  printf 'await db.execute("DROP SCHEMA tenant_a CASCADE");\n' >> "$repo/src/app.ts"
  write_file "$repo" src/reset.ts 'await sql`drop database if exists scratch`;'
  write_file "$repo" src/reset.test.ts 'test("r", () => {});'
  risk "$repo" --worktree
  assert_line "$out" "item data-migration critical floor line src/app.ts:2"
  assert_line "$out" "item data-migration critical floor line src/reset.ts:1"
  # Identifiers that only contain the words are not SQL.
  git -C "$repo" checkout -q -- src/app.ts
  rm "$repo/src/reset.ts" "$repo/src/reset.test.ts"
  printf 'export const dropSchemaCache = dropDatabaseName;\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
}

test_lowercase_truncate_before_quoted_names() {
  local repo
  repo=$(content_repo)
  printf 'await db.raw("truncate `users`");\n' >> "$repo/src/app.ts"
  write_file "$repo" src/wipe.ts 'await db.raw("truncate [dbo].[users]");'
  write_file "$repo" src/wipe.test.ts 'test("w", () => {});'
  risk "$repo" --worktree
  assert_line "$out" "item data-migration critical floor line src/app.ts:2"
  assert_line "$out" "item data-migration critical floor line src/wipe.ts:1"
  git -C "$repo" checkout -q -- src/app.ts
  rm "$repo/src/wipe.ts" "$repo/src/wipe.test.ts"
  printf 'export const s = truncate(text, 10);\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
}

test_uppercase_secret_assignment() {
  local repo value
  repo=$(content_repo)
  value="Zq$(printf 'x9%.0s' 1 2 3 4 5 6 7)"
  printf 'const API_KEY = "%s";\n' "$value" >> "$repo/src/app.ts"
  write_file "$repo" deploy.sh "export STRIPE_SECRET_KEY=$value"
  risk "$repo" --worktree
  assert_line "$out" "item secrets critical floor line src/app.ts:2"
  assert_line "$out" "item secrets critical floor line deploy.sh:1"
  # A reference to the variable is not a value.
  git -C "$repo" checkout -q -- src/app.ts
  rm "$repo/deploy.sh"
  printf 'const API_KEY = process.env.API_KEY;\nAPI_KEY=$(cat /run/secrets/key)\n' >> "$repo/src/app.ts"
  write_file "$repo" run.sh 'export STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY:?}'
  write_file "$repo" ci/build.yml '      - env: { GH_TOKEN: "${{ github.token }}" }'
  risk "$repo" --worktree
  assert_no_line "$out" "secrets"
}

test_lowercase_mutex_is_concurrency() {
  local repo
  repo=$(content_repo)
  write_file "$repo" src/cache.cpp 'std::mutex guard;'
  write_file "$repo" src/pool.c 'pthread_mutex_lock(&lock);'
  write_file "$repo" src/lock.ts 'import { Mutex } from "async-mutex";'
  risk "$repo" --worktree
  assert_line "$out" "item concurrency critical floor line src/cache.cpp:1"
  assert_line "$out" "item concurrency critical floor line src/pool.c:1"
  assert_line "$out" "item concurrency critical floor line src/lock.ts:1"
}

test_auth_and_tenant_symbols_fire_on_removal() {
  local repo
  repo=$(content_repo)
  printf 'const s = await getServerSession(req);\nverifyToken(t);\nwhere({ tenantId });\nwhere({ tenant_id });\n' >> "$repo/src/app.ts"
  commit_all "$repo" guards
  printf 'export const x = 1;\n' > "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_line "$out" "item auth critical floor line src/app.ts:2"
  assert_line "$out" "item tenant-isolation critical floor line src/app.ts:4"
  # Symbols match whole identifiers only.
  git -C "$repo" checkout -q -- src/app.ts
  printf 'verifyTokenShape(t);\nconst tenantIdLabel = "x";\n' >> "$repo/src/app.ts"
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
}
