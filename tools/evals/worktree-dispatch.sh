#!/usr/bin/env bash
# Usage: worktree-dispatch.sh [--model main|sonnet] [--max-budget-usd N] [--root DIR]
#        worktree-dispatch.sh --check TRANSCRIPT REPO
#
# `claude plugin eval` refuses worktree isolation ("unavailable in this session (plugin evaluation
# harness)"), so a real dispatch into a git worktree cannot be a plugin eval case. This runs the
# parallel flow in a scaffolded repository with a plain `claude -p` session that loads the plugin,
# then checks the stream-json transcript and the repository for proof that each builder worked in
# its own worktree and that the results reached main.

set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
# shellcheck source=models.env
. "$here/models.env"

usage() {
  echo "usage: worktree-dispatch.sh [--model main|sonnet] [--max-budget-usd N] [--root DIR] | --check TRANSCRIPT REPO" >&2
  exit 64
}

# check TRANSCRIPT REPO: prints one line per failed assertion and returns 1 when any failed.
check() {
  local transcript=$1 repo=$2 status=0 dispatched worktrees outside
  [ -f "$transcript" ] || { echo "no transcript: $transcript" >&2; return 1; }
  [ -d "$repo" ] || { echo "no repository: $repo" >&2; return 1; }

  dispatched=$(jq -s '[.[] | select(.type == "assistant" and .parent_tool_use_id == null)
    | .message.content[]? | select(.type == "tool_use" and .name == "Agent"
      and (.input.subagent_type | test("^(overdrive:)?builder$")) and .input.isolation == "worktree")] | length' "$transcript")
  [ "${dispatched:-0}" -ge 2 ] || { echo "fewer than 2 builders dispatched with isolation worktree ($dispatched)"; status=1; }

  # The builders' own tool calls carry paths inside distinct harness-created worktrees.
  worktrees=$(jq -rs '[.[] | select(.type == "assistant" and .parent_tool_use_id != null)
    | .message.content[]? | select(.type == "tool_use") | .input
    | (.file_path // .command // "") | capture("/\\.claude/worktrees/(?<id>agent-[0-9a-f]+)")? | .id] | unique | length' "$transcript")
  [ "${worktrees:-0}" -ge 2 ] || { echo "builders worked in fewer than 2 distinct worktrees ($worktrees)"; status=1; }

  outside=$(jq -rs --arg repo "$repo" '[.[] | select(.type == "assistant" and .parent_tool_use_id != null)
    | .message.content[]? | select(.type == "tool_use" and (.name == "Write" or .name == "Edit"))
    | .input.file_path | select(startswith($repo + "/packages/"))] | length' "$transcript")
  [ "${outside:-0}" -eq 0 ] || { echo "$outside builder edits landed in the main checkout instead of a worktree"; status=1; }

  local pkg
  for pkg in pad uniq; do
    git -C "$repo" cat-file -e "HEAD:packages/$pkg/index.js" 2> /dev/null || { echo "packages/$pkg/index.js is not on the checked out branch"; status=1; }
    git -C "$repo" cat-file -e "HEAD:packages/$pkg/test/$pkg.test.js" 2> /dev/null || { echo "packages/$pkg/test/$pkg.test.js is not on the checked out branch"; status=1; }
  done
  (cd "$repo" && node --test packages/pad/test packages/uniq/test > /dev/null 2>&1) || { echo "the integrated packages do not pass node --test"; status=1; }
  return "$status"
}

if [ "${1-}" = --check ]; then
  [ "$#" -eq 3 ] || usage
  check "$2" "$3"
  exit $?
fi

model=sonnet budget=6 root=$(cd "$here/../.." && pwd)
while [ "$#" -gt 0 ]; do
  case $1 in
    --model) model=${2-}; shift 2 || usage ;;
    --max-budget-usd) budget=${2-}; shift 2 || usage ;;
    --root) root=${2-}; shift 2 || usage ;;
    *) usage ;;
  esac
done
model_id=$(od_model_id "$model") || usage

scaffold=$root/plugins/overdrive/evals/e2e/worktree-dispatch/scaffold.sh
prompt=$(cat "$root/plugins/overdrive/evals/e2e/worktree-dispatch/prompt.txt")
dir=$(mktemp -d "${TMPDIR:-/tmp}/od-worktree.XXXXXX") || exit 1
transcript=$dir.jsonl

(cd "$dir" && bash "$scaffold" > /dev/null) || { echo "worktree-dispatch: scaffold failed" >&2; exit 1; }
od_prepare_env || exit 1
(cd "$dir" && claude -p "$prompt" --model "$model_id" --plugin-dir "$root/plugins/overdrive" \
  --permission-mode bypassPermissions --max-budget-usd "$budget" \
  --output-format stream-json --verbose > "$transcript") || { echo "worktree-dispatch: claude failed, transcript at $transcript" >&2; exit 1; }

cost=$(jq -rs '[.[] | select(.type == "result") | .total_cost_usd] | last // 0' "$transcript")
if check "$transcript" "$dir"; then
  echo "worktree dispatch verified (cost \$$cost); repository $dir, transcript $transcript"
else
  echo "worktree dispatch NOT verified (cost \$$cost); repository $dir, transcript $transcript" >&2
  exit 1
fi
