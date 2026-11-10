#!/usr/bin/env bash
# Tests for the assertions of tools/evals/worktree-dispatch.sh.

root=$(dirname "$(dirname "$RUNNER")")
tool() { bash "$root/tools/evals/worktree-dispatch.sh" "$@"; }

agent_line() {
  printf '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","name":"Agent","input":{"subagent_type":"overdrive:builder","isolation":"%s","prompt":"brief"}}]}}\n' "$1"
}

builder_line() {
  printf '{"type":"assistant","parent_tool_use_id":"toolu_%s","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"%s"}}]}}\n' "$1" "$2"
}

# project: a repository whose main branch holds both packages with passing tests.
project() {
  repo=$(make_repo)
  local pkg
  for pkg in pad uniq; do
    write_file "$repo" "packages/$pkg/index.js" "module.exports = {};"
    write_file "$repo" "packages/$pkg/test/$pkg.test.js" "require('node:test')('$pkg', () => {});"
  done
  stage_all "$repo"
  git -C "$repo" commit -q -m "Add packages"
}

transcript() { # ISOLATION PAD_PATH UNIQ_PATH
  {
    agent_line "$1"
    agent_line "$1"
    builder_line a "$2"
    builder_line b "$3"
  } > t.jsonl
}

test_accepts_two_builders_in_distinct_worktrees() {
  project
  transcript worktree "$repo/.claude/worktrees/agent-aaa1/packages/pad/index.js" "$repo/.claude/worktrees/agent-bbb2/packages/uniq/index.js"
  tool --check t.jsonl "$repo"
}

test_ignores_agent_calls_without_a_subagent_type() {
  project
  transcript worktree "$repo/.claude/worktrees/agent-aaa1/packages/pad/index.js" "$repo/.claude/worktrees/agent-bbb2/packages/uniq/index.js"
  printf '{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","name":"Agent","input":{"prompt":"no type"}}]}}\n' >> t.jsonl
  tool --check t.jsonl "$repo"
}

test_rejects_dispatch_without_worktree_isolation() {
  project
  transcript none "$repo/.claude/worktrees/agent-aaa1/packages/pad/index.js" "$repo/.claude/worktrees/agent-bbb2/packages/uniq/index.js"
  assert_exit 1 tool --check t.jsonl "$repo"
}

test_rejects_builders_sharing_one_worktree() {
  project
  transcript worktree "$repo/.claude/worktrees/agent-aaa1/packages/pad/index.js" "$repo/.claude/worktrees/agent-aaa1/packages/uniq/index.js"
  assert_exit 1 tool --check t.jsonl "$repo"
}

test_rejects_builder_edits_in_the_main_checkout() {
  project
  transcript worktree "$repo/.claude/worktrees/agent-aaa1/packages/pad/index.js" "$repo/packages/uniq/index.js"
  assert_exit 1 tool --check t.jsonl "$repo"
}

test_rejects_results_missing_from_main() {
  project
  git -C "$repo" rm -q -r packages/uniq
  git -C "$repo" commit -q -m "Drop uniq"
  transcript worktree "$repo/.claude/worktrees/agent-aaa1/packages/pad/index.js" "$repo/.claude/worktrees/agent-bbb2/packages/uniq/index.js"
  assert_exit 1 tool --check t.jsonl "$repo"
}

test_usage_errors() {
  assert_exit 64 tool --check only-one-argument
  assert_exit 64 tool --nope
}
