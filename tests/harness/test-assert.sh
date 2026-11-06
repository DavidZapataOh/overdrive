#!/usr/bin/env bash
# Tests for the harness itself.

test_assert_line_requires_full_line_match() {
  local out=$'lane critical\nx'
  if assert_line "$out" 'lane crit' 2>/dev/null; then
    echo "partial line matched" >&2
    return 1
  fi
  assert_line "$out" 'lane critical'
}

test_assert_eq() {
  assert_eq a a
  if assert_eq a b 2>/dev/null; then return 1; fi
}

test_assert_no_line() {
  assert_no_line $'one\ntwo' '^three'
  if assert_no_line $'one\ntwo' '^tw' 2>/dev/null; then return 1; fi
}

test_assert_exit() {
  assert_exit 3 bash -c 'exit 3'
  if assert_exit 0 bash -c 'exit 3' 2>/dev/null; then return 1; fi
}

test_assert_file_contains() {
  printf 'alpha\nbeta\n' > f.txt
  assert_file_contains f.txt '^be'
  if assert_file_contains f.txt 'gamma' 2>/dev/null; then return 1; fi
}

test_make_repo_has_one_empty_commit() {
  local repo
  repo=$(make_repo)
  assert_eq 1 "$(git -C "$repo" rev-list --count HEAD)"
  assert_eq "" "$(git -C "$repo" status --porcelain)"
}

test_commit_file_and_stage_all() {
  local repo
  repo=$(make_repo)
  commit_file "$repo" "dir with space/a.txt" "one"
  assert_eq 2 "$(git -C "$repo" rev-list --count HEAD)"
  write_file "$repo" "b.txt" "two"
  stage_all "$repo"
  assert_line "$(git -C "$repo" diff --cached --name-only)" "b.txt"
}

test_runner_isolates_cwd_a() {
  cd /
  LEAKED_VAR=1
  export LEAKED_VAR
}

test_runner_isolates_cwd_b() {
  assert_eq "" "${LEAKED_VAR:-}"
  if [ "$(pwd)" = "/" ]; then return 1; fi
}

test_runner_reports_failure_and_exits_one() {
  local root out rc
  root=$(mktemp -d "${TMPDIR:-/tmp}/od.XXXXXX")
  mkdir "$root/area"
  printf 'test_boom() { return 1; }\ntest_fine() { :; }\n' > "$root/area/test-x.sh"
  rc=0
  out=$(TESTS_DIR="$root" "$BASH" "$RUNNER" 2>&1) || rc=$?
  rm -rf "$root"
  assert_eq 1 "$rc"
  printf '%s\n' "$out" > out.txt
  assert_file_contains out.txt '^not ok 1 test_boom'
  assert_file_contains out.txt '^ok 2 test_fine'
}
