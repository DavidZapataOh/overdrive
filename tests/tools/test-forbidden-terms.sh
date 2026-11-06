#!/usr/bin/env bash
# Tests for tools/check-forbidden-terms.sh. Only the fixture term appears here.

tool() { bash "$(dirname "$(dirname "$RUNNER")")/tools/check-forbidden-terms.sh" "$@"; }

# Runs the tool in REPO with a clean environment plus the given variables.
terms_run() {
  local repo=$1
  shift
  (cd "$repo" && env -u CI -u OVERDRIVE_FORBIDDEN_TERMS -u OVERDRIVE_FORBIDDEN_TERMS_FILE \
    -u GITHUB_HEAD_REF -u GITHUB_REF_NAME "$@")
}

run_tool() { # REPO ENV... -- ARGS...
  local repo=$1
  shift
  local envs=()
  while [ "$1" != "--" ]; do envs+=("$1"); shift; done
  shift
  terms_run "$repo" "${envs[@]}" bash "$(dirname "$(dirname "$RUNNER")")/tools/check-forbidden-terms.sh" "$@"
}

TERM_ENV='OVERDRIVE_FORBIDDEN_TERMS=zebra-term'

test_terms_clean_repo_passes() {
  repo=$(make_repo)
  commit_file "$repo" a.txt "nothing to see"
  run_tool "$repo" "$TERM_ENV" --
}

test_terms_hit_in_file_content() {
  repo=$(make_repo)
  commit_file "$repo" a.txt "a Zebra-Term here"
  out=$(run_tool "$repo" "$TERM_ENV" -- 2>&1) && return 1
  assert_line "$out" "content: a.txt"
}

test_terms_hit_in_file_name() {
  repo=$(make_repo)
  commit_file "$repo" "docs/vs zebra-term.md" "clean"
  out=$(run_tool "$repo" "$TERM_ENV" -- 2>&1) && return 1
  assert_line "$out" "path: docs/vs zebra-term.md"
}

test_terms_hit_in_commit_message() {
  repo=$(make_repo)
  base=$(git -C "$repo" rev-parse HEAD)
  write_file "$repo" a.txt clean
  stage_all "$repo"
  git -C "$repo" commit -q -m "Compare with ZEBRA-TERM"
  head=$(git -C "$repo" rev-parse HEAD)
  out=$(run_tool "$repo" "$TERM_ENV" -- --range "$base..$head" 2>&1) && return 1
  assert_line "$out" "commit message: $head"
}

test_terms_commit_outside_range_is_ignored() {
  repo=$(make_repo)
  write_file "$repo" a.txt clean
  stage_all "$repo"
  git -C "$repo" commit -q -m "zebra-term"
  mid=$(git -C "$repo" rev-parse HEAD)
  commit_file "$repo" b.txt clean
  run_tool "$repo" "$TERM_ENV" -- --range "$mid..HEAD"
}

test_terms_invalid_range_fails_closed() {
  repo=$(make_repo)
  assert_exit 2 run_tool "$repo" "$TERM_ENV" -- --range "deadbeef..HEAD"
}

test_terms_hit_in_branch_name() {
  repo=$(make_repo)
  git -C "$repo" checkout -q -b "feature/zebra-term-compare"
  out=$(run_tool "$repo" "$TERM_ENV" -- 2>&1) && return 1
  assert_line "$out" "branch: feature/zebra-term-compare"
}

test_terms_hit_in_ci_head_ref() {
  repo=$(make_repo)
  out=$(run_tool "$repo" "$TERM_ENV" GITHUB_HEAD_REF=zebra-term-x -- 2>&1) && return 1
  assert_line "$out" "branch: zebra-term-x"
}

test_terms_hit_in_pr_title_and_body() {
  repo=$(make_repo)
  printf '{"pull_request":{"title":"About zebra-term","body":"clean"}}' > "$repo/../event-title.json"
  out=$(run_tool "$repo" "$TERM_ENV" -- --pr-event "$repo/../event-title.json" 2>&1) && return 1
  assert_line "$out" "pull request title"
  printf '{"pull_request":{"title":"clean","body":"line\\nzebra-term"}}' > "$repo/../event-body.json"
  out=$(run_tool "$repo" "$TERM_ENV" -- --pr-event "$repo/../event-body.json" 2>&1) && return 1
  assert_line "$out" "pull request body"
}

test_terms_pr_event_without_pull_request_passes() {
  repo=$(make_repo)
  printf '{"ref":"refs/heads/main"}' > "$repo/../event.json"
  run_tool "$repo" "$TERM_ENV" -- --pr-event "$repo/../event.json"
}

test_terms_staged_scan_sees_uncommitted_content_and_paths() {
  repo=$(make_repo)
  write_file "$repo" a.txt "zebra-term"
  write_file "$repo" "zebra-term.txt" "clean"
  stage_all "$repo"
  out=$(run_tool "$repo" "$TERM_ENV" -- --staged 2>&1) && return 1
  assert_line "$out" "content: a.txt"
  assert_line "$out" "path: zebra-term.txt"
}

test_terms_staged_scan_ignores_untracked_and_unstaged() {
  repo=$(make_repo)
  commit_file "$repo" a.txt clean
  write_file "$repo" a.txt "zebra-term"
  write_file "$repo" new.txt "zebra-term"
  run_tool "$repo" "$TERM_ENV" -- --staged
}

test_terms_message_file() {
  repo=$(make_repo)
  printf 'Fix thing\n\nzebra-term\n' > "$repo/../msg"
  out=$(run_tool "$repo" "$TERM_ENV" -- --message-file "$repo/../msg" 2>&1) && return 1
  assert_line "$out" "commit message file"
  printf 'Fix thing\n' > "$repo/../msg"
  run_tool "$repo" "$TERM_ENV" -- --message-file "$repo/../msg" --staged
}

test_terms_from_file_and_multiple_terms() {
  repo=$(make_repo)
  printf 'other-one\n\nzebra-term\n' > "$repo/../terms"
  commit_file "$repo" a.txt "has other-one"
  out=$(run_tool "$repo" "OVERDRIVE_FORBIDDEN_TERMS_FILE=$repo/../terms" -- 2>&1) && return 1
  assert_line "$out" "content: a.txt"
}

test_terms_blank_lines_never_match_everything() {
  repo=$(make_repo)
  commit_file "$repo" a.txt "clean"
  run_tool "$repo" "OVERDRIVE_FORBIDDEN_TERMS=$(printf '\n\nzebra-term\n\n')" --
}

test_terms_output_does_not_echo_matched_text() {
  repo=$(make_repo)
  commit_file "$repo" a.txt "prefix zebra-term suffix"
  out=$(run_tool "$repo" "$TERM_ENV" -- 2>&1) && return 1
  assert_no_line "$out" 'prefix|suffix'
}

test_terms_binary_content_is_ignored() {
  repo=$(make_repo)
  printf 'zebra-term\0binary' > "$repo/blob.bin"
  stage_all "$repo"
  git -C "$repo" commit -q -m blob
  run_tool "$repo" "$TERM_ENV" --
}

test_terms_missing_in_ci_exits_2() {
  repo=$(make_repo)
  assert_exit 2 run_tool "$repo" CI=true --
  assert_exit 2 run_tool "$repo" CI=true OVERDRIVE_FORBIDDEN_TERMS= --
  assert_exit 2 run_tool "$repo" CI=true "OVERDRIVE_FORBIDDEN_TERMS=$(printf '\n \n')" --
}

test_terms_missing_outside_ci_is_skipped_with_notice() {
  repo=$(make_repo)
  out=$(run_tool "$repo" -- 2>&1)
  assert_file_contains /dev/stdin 'no forbidden terms configured' <<<"$out"
}

test_terms_outside_git_exits_2() {
  mkdir plain
  assert_exit 2 run_tool plain "$TERM_ENV" --
}

test_terms_unknown_option_exits_2() {
  repo=$(make_repo)
  assert_exit 2 run_tool "$repo" "$TERM_ENV" -- --bogus
}
