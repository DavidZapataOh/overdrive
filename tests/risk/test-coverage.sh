#!/usr/bin/env bash
# Tests for overdrive risk: which tests cover a change (untested-change), which files are
# tests, and which edits remove test cases (test-removed).

# shellcheck source=helpers.sh
. "$(dirname "$RUNNER")/risk/helpers.sh"

untested() {
  printf '%s\n' "$out" | awk '$1 == "item" && $2 == "untested-change" { print $NF }' | LC_ALL=C sort | paste -s -d ' ' -
}

test_changed_test_covers_only_its_stem_or_directory() {
  local repo
  repo=$(make_repo)
  write_file "$repo" src/a/format.ts 'export const f = 1;'
  write_file "$repo" src/b/other.ts 'export const o = 1;'
  write_file "$repo" src/c/thing.ts 'export const t = 1;'
  write_file "$repo" src/d/lonely.ts 'export const l = 1;'
  commit_all "$repo" base
  for f in src/a/format.ts src/b/other.ts src/c/thing.ts src/d/lonely.ts; do
    printf '// more\n' >> "$repo/$f"
  done
  # Same directory, another stem.
  write_file "$repo" src/a/helpers.test.ts 'test("h", () => {});'
  # Same stem, another directory.
  write_file "$repo" e2e/other.spec.ts 'test("o", () => {});'
  # A sibling __tests__ directory is the source's directory.
  write_file "$repo" src/c/__tests__/misc.test.ts 'test("m", () => {});'
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_eq "src/d/lonely.ts" "$(untested)"
}

test_sibling_test_lookup_is_nearest_package() {
  local repo
  repo=$(make_repo)
  write_file "$repo" packages/a/package.json '{}'
  write_file "$repo" packages/a/src/index.ts 'export const a = 1;'
  write_file "$repo" packages/a/src/index.test.ts 'test("a", () => {});'
  write_file "$repo" packages/b/package.json '{}'
  write_file "$repo" packages/b/src/index.ts 'export const b = 1;'
  write_file "$repo" packages/b/src/util/date.ts 'export const d = 1;'
  write_file "$repo" packages/b/test/util/date.test.ts 'test("d", () => {});'
  write_file "$repo" packages/b/src/util/slug.ts 'export const s = 1;'
  write_file "$repo" packages/b/test/slug.test.ts 'test("s", () => {});'
  write_file "$repo" packages/b/src/__tests__/parse.test.ts 'test("p", () => {});'
  write_file "$repo" packages/b/src/parse.ts 'export const p = 1;'
  write_file "$repo" svc/pom.xml '<project/>'
  write_file "$repo" svc/src/main/java/com/acme/Billing.java 'class Billing {}'
  write_file "$repo" svc/src/test/java/com/acme/BillingTest.java 'class BillingTest {}'
  write_file "$repo" crates/lex/Cargo.toml '[package]'
  write_file "$repo" crates/lex/src/scan.rs 'fn scan() {}'
  write_file "$repo" crates/lex/tests/scan.rs 'fn t() {}'
  write_file "$repo" app/models.py 'x = 1'
  write_file "$repo" tests/test_models.py 'def test_m(): pass'
  commit_all "$repo" base
  for f in packages/b/src/index.ts packages/b/src/util/date.ts packages/b/src/util/slug.ts \
    packages/b/src/parse.ts svc/src/main/java/com/acme/Billing.java crates/lex/src/scan.rs app/models.py; do
    printf '// more\n' >> "$repo/$f"
  done
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code: $(cat err)"
  # packages/a's index test is in another package; packages/b's slug test does not mirror util/.
  assert_eq "packages/b/src/index.ts packages/b/src/util/slug.ts" "$(untested)"

  # The same lookup reads the range's end commit in a bare repository.
  git -C "$repo" add -A
  git -C "$repo" commit -q -m more
  git clone -q --bare "$repo" "$PWD/bare.git"
  risk "$PWD/bare.git" --diff HEAD~1..HEAD
  assert_eq "packages/b/src/index.ts packages/b/src/util/slug.ts" "$(untested)"
}

test_test_files_of_other_languages() {
  local repo f files
  repo=$(make_repo)
  files='src/test/java/com/acme/OrderTest.java src/test/kotlin/com/acme/LedgerTests.kt
    src/test/java/com/acme/Fixtures.java AppTests/AppTests.swift Api.Tests/UserTests.cs
    spec/models/user_spec.rb test/test_user.rb test/user_test.rb tests/integration.rs'
  for f in $files; do write_file "$repo" "$f" 'x'; done
  write_file "$repo" packages/core/src/test/utils.ts 'export const u = 1;'
  commit_all "$repo" base
  # shellcheck disable=SC2086
  git -C "$repo" rm -q $files packages/core/src/test/utils.ts
  risk "$repo" --staged
  assert_eq 0 "$rc" "exit code: $(cat err)"
  for f in $files; do
    assert_line "$out" "item test-removed critical computed path $f"
  done
  # src/test/ holds tests only for the JVM languages; a TypeScript helper there is a file.
  assert_line "$out" "item deletion standard computed path packages/core/src/test/utils.ts"
  assert_eq "Risk: critical — test-removed, deletion" "$(risk_line)"
}

test_test_naming_names_the_stem() {
  local repo
  repo=$(make_repo)
  write_file "$repo" lib/user.rb 'class User; end'
  write_file "$repo" spec/user_spec.rb 'describe User do; end'
  write_file "$repo" lib/order.rb 'class Order; end'
  write_file "$repo" test/test_order.rb 'class TestOrder; end'
  commit_all "$repo" base
  for f in lib/user.rb lib/order.rb; do
    printf '# more\n' >> "$repo/$f"
  done
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_eq "" "$(untested)"
  assert_line "$out" "lane direct"
}

test_commented_test_cases_do_not_count() {
  local repo
  repo=$(make_repo)
  write_file "$repo" src/math.ts 'export const add = 1;'
  printf 'it("a", () => {});\nit("b", () => {});\n' > "$repo/src/math.test.ts"
  mkdir -p "$repo/tests"
  printf 'def test_a():\n    pass\n' > "$repo/tests/test_slug.py"
  write_file "$repo" src/slug.py 'x = 1'
  commit_all "$repo" base
  # Commenting a case out removes it, and a commented case added elsewhere is no case.
  printf 'it("a", () => {});\n// it("b", () => {});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_line "$out" "item test-removed critical computed path src/math.test.ts"
  printf '# def test_a():\n#     pass\n' > "$repo/tests/test_slug.py"
  risk "$repo" --worktree
  assert_line "$out" "item test-removed critical computed path tests/test_slug.py"

  # Rust attributes start with # and are not comments.
  git -C "$repo" checkout -q -- .
  write_file "$repo" crates/x/tests/parse.rs '#[test]
fn parses() {}'
  commit_all "$repo" rust
  write_file "$repo" crates/x/tests/parse.rs '#[test]
fn parses_again() {}'
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
}

test_skip_and_only_wrappers_remove_test_cases() {
  local repo f
  repo=$(make_repo)
  write_file "$repo" src/math.ts 'export const add = 1;'
  printf 'describe("m", () => {\n  it("a", () => {});\n  it("b", () => {});\n});\n' > "$repo/src/math.test.ts"
  commit_all "$repo" base
  for f in 'describe.skip("m", () => {' 'describe.only("m", () => {' 'test.describe.skip("m", () => {' \
    'xdescribe("m", () => {'; do
    printf '%s\n  it("a", () => {});\n  it("b", () => {});\n});\n' "$f" > "$repo/src/math.test.ts"
    risk "$repo" --worktree
    assert_line "$out" "item test-removed critical computed path src/math.test.ts"
  done
  printf 'describe("m", () => {\n  it.skip("a", () => {});\n  it("b", () => {});\n});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_line "$out" "item test-removed critical computed path src/math.test.ts"
  printf 'describe("m", () => {\n  it("a", () => {});\n  it("b", () => {});\n  it.only("c", () => {});\n});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_line "$out" "item test-removed critical computed path src/math.test.ts"

  # Other runners: pytest, Go, JUnit, Rust.
  git -C "$repo" checkout -q -- .
  mkdir -p "$repo/tests" "$repo/pkg" "$repo/src/test/java" "$repo/crates/x/tests"
  printf 'def test_a():\n    pass\n' > "$repo/tests/test_a.py"
  printf 'func TestA(t *testing.T) {\n}\n' > "$repo/pkg/a_test.go"
  printf 'class ATest {\n  @Test\n  void a() {}\n}\n' > "$repo/src/test/java/ATest.java"
  printf '#[test]\nfn a() {}\n' > "$repo/crates/x/tests/a.rs"
  commit_all "$repo" more
  printf '@pytest.mark.skip\ndef test_a():\n    pass\n' > "$repo/tests/test_a.py"
  printf 'func TestA(t *testing.T) {\n\tt.Skip("later")\n}\n' > "$repo/pkg/a_test.go"
  printf 'class ATest {\n  @Disabled\n  @Test\n  void a() {}\n}\n' > "$repo/src/test/java/ATest.java"
  printf '#[test]\n#[ignore]\nfn a() {}\n' > "$repo/crates/x/tests/a.rs"
  risk "$repo" --worktree
  for f in tests/test_a.py pkg/a_test.go src/test/java/ATest.java crates/x/tests/a.rs; do
    assert_line "$out" "item test-removed critical computed path $f"
  done
}

test_removing_skipped_or_focused_cases_gives_no_credit() {
  local repo wrapper
  repo=$(make_repo)
  write_file "$repo" src/math.ts 'export const add = 1;'
  for wrapper in 'it.skip' 'it.only' 'xit'; do
    printf 'it("live", () => {});\n%s("sk", () => {});\nit("c", () => {});\n' "$wrapper" > "$repo/src/math.test.ts"
    commit_all "$repo" "base $wrapper"
    # Deleting a live case and a skipped (or focused) one removes at least one live case.
    printf 'it("c", () => {});\n' > "$repo/src/math.test.ts"
    risk "$repo" --worktree
    assert_line "$out" "item test-removed critical computed path src/math.test.ts"
  done
  # Dropping only a skipped case removes no live case, and adds none either.
  printf 'it("a", () => {});\nit.skip("b", () => {});\n' > "$repo/src/math.test.ts"
  commit_all "$repo" skipped
  printf 'it("a", () => {});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_no_line "$out" "test-removed"
  # Renaming a skipped case skips nothing new.
  printf 'it("a", () => {});\nit.skip("b renamed", () => {});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_no_line "$out" "test-removed"
  # Unfocusing a suite runs more cases, not fewer.
  printf 'describe.only("m", () => {\n  it("a", () => {});\n});\n' > "$repo/src/math.test.ts"
  commit_all "$repo" focused
  printf 'describe("m", () => {\n  it("a", () => {});\n});\n' > "$repo/src/math.test.ts"
  risk "$repo" --worktree
  assert_no_line "$out" "test-removed"
}

test_changed_test_covers_same_stem_only_in_its_package() {
  local repo
  repo=$(make_repo)
  write_file "$repo" packages/a/package.json '{}'
  write_file "$repo" packages/b/package.json '{}'
  write_file "$repo" packages/a/src/format.ts 'export const f = 1;'
  commit_all "$repo" base
  printf '// more\n' >> "$repo/packages/a/src/format.ts"
  write_file "$repo" packages/b/test/format.test.ts 'test("f", () => {});'
  risk "$repo" --worktree
  assert_line "$out" "item untested-change critical computed path packages/a/src/format.ts"
  write_file "$repo" packages/a/e2e/format.spec.ts 'test("f", () => {});'
  risk "$repo" --worktree
  assert_no_line "$out" "untested-change"
}

test_test_suffix_counts_only_under_a_test_directory() {
  local repo
  repo=$(make_repo)
  write_file "$repo" src/main/java/com/acme/LoadTest.java 'class LoadTest {}'
  write_file "$repo" app/src/androidTest/java/com/acme/CartTest.kt 'class CartTest'
  write_file "$repo" Tests/AppTests/RouterTests.swift 'final class RouterTests {}'
  commit_all "$repo" base
  git -C "$repo" rm -q app/src/androidTest/java/com/acme/CartTest.kt Tests/AppTests/RouterTests.swift
  printf '// more\n' >> "$repo/src/main/java/com/acme/LoadTest.java"
  risk "$repo" --worktree
  assert_line "$out" "item untested-change critical computed path src/main/java/com/acme/LoadTest.java"
  assert_line "$out" "item test-removed critical computed path app/src/androidTest/java/com/acme/CartTest.kt"
  assert_line "$out" "item test-removed critical computed path Tests/AppTests/RouterTests.swift"
}

# import_repo: a package with src/app.js and src/lib/index.js, tests that import them
# only through helpers, committed as the base.
import_repo() {
  local repo
  repo=$(make_repo)
  write_file "$repo" package.json '{}'
  write_file "$repo" src/app.js 'module.exports = {};'
  write_file "$repo" src/lib/index.js 'module.exports = {};'
  write_file "$repo" src/orphan.js 'module.exports = {};'
  write_file "$repo" test/helpers.js "const { createApp } = require('../src/app.js');"
  commit_all "$repo" base
  printf '%s\n' "$repo"
}

change_sources() {
  printf '// more\n' >> "$1/src/app.js"
  printf '// more\n' >> "$1/src/lib/index.js"
  printf '// more\n' >> "$1/src/orphan.js"
}

test_a_test_the_change_carries_covers_the_sources_it_imports() {
  local repo
  repo=$(import_repo)
  change_sources "$repo"
  write_file "$repo" test/export.test.js "const { createApp } = require('../src/app.js');
const lib = require('../src/lib');
test('x', () => {});"
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_eq "src/orphan.js" "$(untested)"
}

test_imports_through_a_helper_cover_the_source() {
  local repo
  repo=$(import_repo)
  printf '// more\n' >> "$repo/src/app.js"
  write_file "$repo" test/products.test.js "const { withApp } = require('./helpers.js');
test('x', () => {});"
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_eq "" "$(untested)"
}

test_a_carried_test_that_imports_nothing_changed_covers_nothing() {
  local repo
  repo=$(import_repo)
  printf '// more\n' >> "$repo/src/orphan.js"
  write_file "$repo" test/export.test.js "const { withApp } = require('./helpers.js');
test('x', () => {});"
  risk "$repo" --worktree
  assert_eq "src/orphan.js" "$(untested)"
}

test_an_edited_test_keeps_the_imports_it_already_had() {
  local repo
  repo=$(import_repo)
  write_file "$repo" test/export.test.js "const { createApp } = require('../src/app');
test('a', () => {});"
  commit_all "$repo" 'add test'
  printf '// more\n' >> "$repo/src/app.js"
  printf "test('b', () => {});\n" >> "$repo/test/export.test.js"
  risk "$repo" --worktree
  assert_eq "" "$(untested)"
}

test_import_coverage_is_the_same_in_every_mode() {
  local repo base
  repo=$(import_repo)
  base=$(git -C "$repo" rev-parse HEAD)
  printf '// more\n' >> "$repo/src/app.js"
  printf '// more\n' >> "$repo/src/orphan.js"
  write_file "$repo" test/export.test.js "const { createApp } = require('../src/app.js');
test('x', () => {});"
  risk "$repo" --worktree
  assert_eq "src/orphan.js" "$(untested)" worktree
  git -C "$repo" add -A
  risk "$repo" --staged
  assert_eq "src/orphan.js" "$(untested)" staged
  git -C "$repo" commit -q -m change
  risk "$repo" --diff "$base...HEAD"
  assert_eq "src/orphan.js" "$(untested)" "diff three dots"
  risk "$repo" --diff "$base..HEAD"
  assert_eq "src/orphan.js" "$(untested)" "diff two dots"
}

test_import_coverage_ignores_files_outside_the_repository_listing() {
  local repo
  repo=$(import_repo)
  printf '// more\n' >> "$repo/src/orphan.js"
  write_file "$repo" test/export.test.js "const x = require('../../elsewhere/src/orphan.js');
test('x', () => {});"
  risk "$repo" --worktree
  assert_eq "src/orphan.js" "$(untested)"
}
