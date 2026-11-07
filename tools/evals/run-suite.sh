#!/usr/bin/env bash
# Usage: run-suite.sh SKILL --tier smoke|full|pressure [--model main|sonnet] [--max-cost-usd N]
#                     [--root DIR] [--allow-tools TOOL...]
#
# smoke     one run, no baseline, free graders only (cases tagged SKILL-smoke)
# full      trigger and behavior cases, three runs per arm, writes the skill's RESULTS.md
# pressure  every pressure scenario with the plugin, five runs, final messages kept for reading

set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
# shellcheck source=models.env
. "$here/models.env"

usage() {
  echo "usage: run-suite.sh SKILL --tier smoke|full|pressure [--model main|sonnet] [--max-cost-usd N] [--root DIR] [--allow-tools TOOL...]" >&2
  exit 64
}

[ "$#" -ge 1 ] || usage
skill=$1
shift
tier='' model=main cost='' root=$(cd "$here/../.." && pwd) allow=''
while [ "$#" -gt 0 ]; do
  case $1 in
    --tier) tier=${2-}; shift 2 || usage ;;
    --model) model=${2-}; shift 2 || usage ;;
    --max-cost-usd) cost=${2-}; shift 2 || usage ;;
    --root) root=${2-}; shift 2 || usage ;;
    --allow-tools)
      shift
      while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do
        allow="$allow${allow:+ }$1"
        shift
      done
      [ -n "$allow" ] || usage
      ;;
    *) usage ;;
  esac
done
case $tier in smoke | full | pressure) ;; *) usage ;; esac
model_id=$(od_model_id "$model") || usage

plugin=plugins/overdrive
[ -d "$root/$plugin/evals/$skill" ] || { echo "run-suite: no evals for skill $skill" >&2; exit 1; }
cd "$root" || exit 1

if [ "$tier" = pressure ]; then
  status=0
  for dir in "$root/$plugin/evals/$skill/pressure"/*/; do
    [ -d "$dir" ] || continue
    scenario=$(basename "$dir")
    args=(--arm with --model "$model" --root "$root")
    [ -z "$cost" ] || args+=(--max-cost-usd "$cost")
    bash "$here/pressure.sh" "$skill" "$scenario" "${args[@]}" || status=$?
  done
  exit "$status"
fi

results_dir=$root/$plugin/evals/results
mkdir -p "$results_dir" || exit 1
json=$results_dir/$skill-$tier.json
rm -f "$json"

args=(plugin eval "$plugin" --trust-plugin --scaffold --no-publish)
judge=''
case $tier in
  smoke)
    args+=(--ablation none --runs 1 --max-cost-usd "${cost:-2}" --model "$model_id" --json "$json" --tag "$skill-smoke")
    ;;
  full)
    judge=$OD_EVAL_JUDGE
    args+=(--ablation with-without --runs 3 --threshold 0.9 --max-cost-usd "${cost:-25}" --model "$model_id"
      --judge-model "$judge" --json "$json" --tag "$skill-trigger" "$skill-behavior")
    ;;
esac
# shellcheck disable=SC2206 # tool grants are single words or Tool(pattern) without spaces
[ -z "$allow" ] || args+=(--allow-tools $allow)

# The summary is the only thing on stdout: CI appends it to the job summary.
claude "${args[@]}" >&2
rc=$?
if [ ! -s "$json" ]; then
  echo "run-suite: claude plugin eval wrote no result (exit $rc)" >&2
  [ "$rc" -ne 0 ] && exit "$rc"
  exit 1
fi

summary=$(bash "$here/summarize.sh" --skill "$skill" --tier "$tier" --model "$model_id" ${judge:+--judge "$judge"} "$json") || exit 1
printf '%s\n' "$summary"

# A run that errored (timeout, rate limit) is not evidence, whatever the command exited with.
if [ "$rc" -eq 0 ] && [ "$(jq '[.cases[].arms.with[] | select(.error != null)] | length' "$json")" -gt 0 ]; then
  echo "run-suite: some runs ended with an error; treating the suite as failed" >&2
  rc=1
fi

if [ "$tier" = full ] && [ "$(jq -r '.partial' "$json")" != true ]; then
  printf '%s\n' "$summary" > "$root/$plugin/evals/$skill/RESULTS.md"
fi
exit "$rc"
