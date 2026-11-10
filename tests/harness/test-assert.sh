#!/usr/bin/env bash
# shellcheck disable=SC2016
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

# Runs the runner on a fixture file; sets RUN_OUT and RUN_RC.
run_fixture() {
  local root
  root=$(mktemp -d "${TMPDIR:-/tmp}/od.XXXXXX")
  mkdir "$root/area"
  printf '%s\n' "$1" > "$root/area/test-x.sh"
  RUN_RC=0
  RUN_OUT=$(TESTS_DIR="$root" "$BASH" "$RUNNER" 2>&1) || RUN_RC=$?
  rm -rf "$root"
}

test_runner_isolates_cwd_and_state() {
  run_fixture 'test_a_leaks() { cd /; LEAKED_VAR=1; export LEAKED_VAR; }
test_b_clean() { [ -z "${LEAKED_VAR:-}" ] && [ "$(pwd)" != "/" ]; }'
  assert_eq 0 "$RUN_RC"
  assert_line "$RUN_OUT" 'ok 1 test_a_leaks'
  assert_line "$RUN_OUT" 'ok 2 test_b_clean'
}

test_runner_reports_failure_and_exits_one() {
  run_fixture 'test_boom() { return 1; }
test_fine() { :; }'
  assert_eq 1 "$RUN_RC"
  assert_line "$RUN_OUT" 'not ok 1 test_boom'
  assert_line "$RUN_OUT" 'ok 2 test_fine'
}

test_runner_fails_on_first_failing_assertion() {
  run_fixture 'test_bad() { assert_eq 1 2; echo after; }'
  assert_eq 1 "$RUN_RC"
  assert_line "$RUN_OUT" 'not ok 1 test_bad'
  assert_no_line "$RUN_OUT" '^ok '
}

test_runner_fails_on_failure_inside_helper() {
  run_fixture 'helper() { assert_eq a b; echo still; }
test_bad() { helper; echo after; }'
  assert_eq 1 "$RUN_RC"
  assert_line "$RUN_OUT" 'not ok 1 test_bad'
}

test_runner_removes_locked_directories_left_by_tests() {
  local run_sh=$RUNNER fixtures=$PWD/fx tmp=$PWD/tmp rc=0
  mkdir -p "$fixtures" "$tmp"
  cat > "$fixtures/test-locked.sh" <<'EOT'
test_locks_a_directory() {
  mkdir -p "$TMPDIR/sealed/inner" "$TMPDIR/ro"
  : > "$TMPDIR/sealed/inner/f"
  chmod 000 "$TMPDIR/sealed"
  chmod 500 "$TMPDIR/ro"
}
EOT
  TMPDIR=$tmp TESTS_DIR=$fixtures "$BASH" "$run_sh" > out 2> err || rc=$?
  assert_eq 0 "$rc" "runner exit code"
  [ ! -s err ] || { cat err >&2; return 1; }
  assert_eq 0 "$(find "$tmp" -mindepth 1 | wc -l | tr -d ' ')" "leftovers"
}
