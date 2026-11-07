#!/usr/bin/env bash
# Usage: pressure.sh SKILL SCENARIO --arm with|without [--runs N] [--model main|sonnet]
#                    [--max-cost-usd N] [--root DIR]
# Runs one pressure scenario and writes each run's final message to
# tests/pressure/SKILL/SCENARIO/runs/ARM-N.md for reading by hand.
#
# The without arm runs the same scenario under an empty plugin, because
# `claude plugin eval` cannot run a baseline arm on its own.

set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
# shellcheck source=models.env
. "$here/models.env"

usage() {
  echo "usage: pressure.sh SKILL SCENARIO --arm with|without [--runs N] [--model main|sonnet] [--max-cost-usd N] [--root DIR]" >&2
  exit 64
}

[ "$#" -ge 2 ] || usage
skill=$1 scenario=$2
shift 2
arm='' runs=5 model=main cost=15 root=$(cd "$here/../.." && pwd)
while [ "$#" -gt 0 ]; do
  [ "$#" -ge 2 ] || usage
  case $1 in
    --arm) arm=$2 ;;
    --runs) runs=$2 ;;
    --model) model=$2 ;;
    --max-cost-usd) cost=$2 ;;
    --root) root=$2 ;;
    *) usage ;;
  esac
  shift 2
done
case $arm in with | without) ;; *) usage ;; esac
case $runs in '' | *[!0-9]* | 0) usage ;; esac
model_id=$(od_model_id "$model") || usage

plugin=plugins/overdrive
scenario_dir=$root/$plugin/evals/$skill/pressure/$scenario
[ -d "$scenario_dir" ] || { echo "pressure: no scenario $skill/$scenario" >&2; exit 1; }

work=$(mktemp -d "${TMPDIR:-/tmp}/od-pressure.XXXXXX") || exit 1
trap 'rm -rf "$work"' EXIT

cd "$root" || exit 1
target=$plugin
if [ "$arm" = without ]; then
  target=$work/empty-plugin
  mkdir -p "$target/.claude-plugin" "$target/evals/$skill/pressure"
  printf '{"name":"no-plugin","version":"0.0.0","description":"Empty plugin that stands in for the no-plugin arm."}\n' > "$target/.claude-plugin/plugin.json"
  [ ! -d "$root/$plugin/evals/_lib" ] || cp -R "$root/$plugin/evals/_lib" "$target/evals/_lib"
  cp -R "$scenario_dir" "$target/evals/$skill/pressure/$scenario"
fi

result=$work/result.json
claude plugin eval "$target" --trust-plugin --scaffold --no-publish --ablation none --runs "$runs" \
  --keep-temp --max-cost-usd "$cost" --model "$model_id" --case "$scenario" --tag "$skill-pressure" \
  --json "$result" > /dev/null
rc=$?
if [ ! -s "$result" ]; then
  echo "pressure: claude plugin eval wrote no result (exit $rc)" >&2
  exit 1
fi


final_message() {
  local text
  text=$(jq -rs 'map(select(.type == "result" and (.result | type) == "string")) | last | .result // empty' "$1")
  if [ -z "$text" ]; then
    text=$(jq -rs '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text] | last // ""' "$1")
  fi
  printf '%s\n' "$text"
}

runs_tsv=$work/runs.tsv
if ! jq -r '.cases[0].arms.with[] | [.tracePath // "", .error // ""] | @tsv' "$result" > "$runs_tsv"; then
  echo "pressure: no case ran: $skill/$scenario matched nothing in the result" >&2
  exit 1
fi
if [ ! -s "$runs_tsv" ]; then
  echo "pressure: $skill/$scenario produced no runs" >&2
  exit 1
fi

out_dir=$root/tests/pressure/$skill/$scenario/runs
mkdir -p "$out_dir" || exit 1
rm -f "$out_dir/$arm"-*.md

n=0
while IFS=$'\t' read -r trace err; do
  n=$((n + 1))
  dest=$out_dir/$arm-$n.md
  if [ -n "$trace" ] && [ -f "$trace" ]; then
    final_message "$trace" > "$dest"
  else
    printf 'RUN ERROR: %s\n' "${err:-no trace was kept}" > "$dest"
  fi
  if [ -n "$trace" ]; then
    kept=$(dirname "$(dirname "$trace")")
    case $(basename "$kept") in
      claude-eval-*)
        chmod -R u+rwx "$kept" 2>/dev/null
        rm -rf "$kept"
        ;;
    esac
  fi
done < "$runs_tsv"

printf 'pressure: wrote %d run(s) to %s\n' "$n" "$out_dir"
[ "$rc" -ge 2 ] && exit "$rc"
exit 0
