#!/usr/bin/env bash
# Usage: pressure.sh SKILL SCENARIO --arm with|without [--runs N] [--model main|sonnet]
#                    [--max-cost-usd N] [--root DIR]
# Runs one pressure scenario and writes each run to tests/pressure/SKILL/SCENARIO/runs/ARM-N.md for
# reading by hand: every assistant text block in order, then the final message under its own heading.
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
# Case names carry the skill, so --case never matches another skill's scenario of the same name.
case_name=$skill-$scenario
scenario_dir=$root/$plugin/evals/$skill/pressure/$case_name
[ -d "$scenario_dir" ] || { echo "pressure: no scenario $skill/$scenario" >&2; exit 1; }

od_prepare_env || exit 1

work=$(mktemp -d "${TMPDIR:-/tmp}/od-pressure.XXXXXX") || exit 1
trap 'rm -rf "$work"' EXIT

cd "$root" || exit 1
target=$plugin
if [ "$arm" = without ]; then
  target=$work/empty-plugin
  mkdir -p "$target/.claude-plugin" "$target/evals/$skill/pressure"
  printf '{"name":"no-plugin","version":"0.0.0","description":"Empty plugin that stands in for the no-plugin arm."}\n' > "$target/.claude-plugin/plugin.json"
  [ ! -d "$root/$plugin/evals/_lib" ] || cp -R "$root/$plugin/evals/_lib" "$target/evals/_lib"
  cp -R "$scenario_dir" "$target/evals/$skill/pressure/$case_name"
fi

# Same grant file as run-suite.sh, one tool per line.
allow=()
grants=$root/$plugin/evals/$skill/allow-tools
if [ -f "$grants" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case $line in '' | '#'*) continue ;; esac
    allow+=("$line")
  done < "$grants"
fi

result=$work/result.json
args=(plugin eval "$target" --trust-plugin --scaffold --no-publish --ablation none --runs "$runs"
  --keep-temp --max-cost-usd "$cost" --model "$model_id" --case "$case_name" --tag "$skill-pressure")
[ "${#allow[@]}" -eq 0 ] || args+=(--allow-tools "${allow[@]}")
claude "${args[@]}" --json "$result" > /dev/null
rc=$?
if [ ! -s "$result" ]; then
  echo "pressure: claude plugin eval wrote no result (exit $rc)" >&2
  exit 1
fi


# The Stop hook can ask for a second reply or replace the last one, so the final message alone can
# hide what the model said earlier in the run.
assistant_texts() {
  jq -rs '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text]
    | to_entries | .[] | "## Assistant text \(.key + 1)\n\n\(.value)\n"' "$1"
}

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
bad=0
while IFS=$'\t' read -r trace err; do
  n=$((n + 1))
  [ -z "$err" ] || bad=$((bad + 1))
  dest=$out_dir/$arm-$n.md
  if [ -n "$trace" ] && [ -f "$trace" ]; then
    {
      [ -z "$err" ] || printf 'RUN ERROR: %s\n\n' "$err"
      assistant_texts "$trace"
      printf '## Final message\n\n'
      final_message "$trace"
    } > "$dest"
  else
    [ -n "$err" ] || bad=$((bad + 1))
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
jq -r '"\(.costUsd // 0) \(.durationSeconds // 0)"' "$result" | awk '{ printf "pressure: cost $%.2f, %s s\n", $1, $2 }'
[ "$rc" -ge 2 ] && exit "$rc"
if [ "$bad" -gt 0 ] || [ "$n" -lt "$runs" ]; then
  printf 'pressure: %d of %d requested run(s) recorded, %d errored\n' "$n" "$runs" "$bad" >&2
  exit 1
fi
exit 0
