#!/usr/bin/env bash
# The eval transcript ignore rules must hide session files only, never a tracked case directory.

root=$(dirname "$(dirname "$RUNNER")")
uuid=7c1d0a54-3b52-4a7e-9c0e-3a1f2b9d6e11

test_no_tracked_file_matches_an_ignore_rule() {
  local hits
  hits=$(git -C "$root" ls-files -ci --exclude-standard)
  [ -z "$hits" ] || { printf 'tracked files are ignored:\n%s\n' "$hits" >&2; return 1; }
}

test_session_files_and_directories_are_ignored() {
  git -C "$root" check-ignore -q "plugins/overdrive/evals/x/behavior/c/$uuid.jsonl" || { echo "session jsonl not ignored" >&2; return 1; }
  git -C "$root" check-ignore -q "plugins/overdrive/evals/x/behavior/c/$uuid/subagents/a.jsonl" || { echo "session directory not ignored" >&2; return 1; }
}

test_case_directories_named_like_words_are_not_ignored() {
  if git -C "$root" check-ignore -q "plugins/overdrive/evals/compound-learning/behavior/compound-learning-behavior-correction-becomes-check/graders/new.md"; then
    echo "a case directory is ignored" >&2
    return 1
  fi
}
