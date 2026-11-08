#!/usr/bin/env bash
# Tests for the stand-in gh that eval runs put first on PATH.

root=$(dirname "$(dirname "$RUNNER")")
gh=$root/tools/evals/bin/gh

repo() {
  git init -q -b main . || return 1
}

test_logs_each_call_in_the_repository_root() {
  repo
  mkdir sub
  (cd sub && "$gh" pr checks 7 --watch --fail-fast > /dev/null)
  "$gh" run list --json databaseId > /dev/null
  [ "$(cat .gh-calls.log)" = "pr checks 7 --watch --fail-fast
run list --json databaseId" ]
}

test_pr_create_prints_the_url_and_needs_the_body_file() {
  repo
  if "$gh" pr create --title x --body-file missing.md 2> err.txt; then
    echo "created a pull request without its body file" >&2
    return 1
  fi
  assert_file_contains err.txt 'no such file'
  echo body > body.md
  [ "$("$gh" pr create --title x --body-file body.md)" = https://github.com/acme/shop/pull/7 ]
}

test_merge_refuses_auto_and_merges_otherwise() {
  repo
  if "$gh" pr merge 7 --auto --merge 2> err.txt; then return 1; fi
  assert_file_contains err.txt 'enablePullRequestAutoMerge'
  "$gh" pr merge 7 --merge | grep -q '^✓ Merged'
  [ "$(wc -l < .gh-calls.log | tr -d ' ')" = 2 ]
}

test_run_list_prints_json_and_checks_exit_zero() {
  repo
  "$gh" run list | grep -q '"databaseId":1001'
  "$gh" pr checks 7 --watch > /dev/null
}

test_unknown_commands_fail_loudly_but_are_logged() {
  repo
  if "$gh" release delete v1 2> err.txt; then return 1; fi
  assert_file_contains err.txt unsupported
  [ "$(cat .gh-calls.log)" = "release delete v1" ]
}
