#!/usr/bin/env bash
# Usage: run-suite.sh SKILL --tier smoke|full|pressure|e2e [--model main|sonnet] [--max-cost-usd N]
#                     [--runs N] [--concurrency N] [--case GLOB] [--root DIR] [--allow-tools TOOL...]
#
# --case GLOB narrows the tier to the cases whose name matches (the CLI's own --case), so a fix round
# reruns only what it changed. A narrowed full run is partial and does not write RESULTS.md.
#
# smoke     one run, no baseline, free graders only (cases tagged SKILL-smoke)
# full      trigger and behavior cases, three runs per arm, writes the skill's RESULTS.md
# pressure  every pressure scenario with the plugin, five runs, final messages kept for reading
# e2e       behavior cases of the e2e suite, with-arm only, three runs (--runs N overrides), sandboxes
#           kept so the traces can be read; long and costly, so never part of smoke or full and
#           never writes RESULTS.md

set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"
# shellcheck source=models.env
. "$here/models.env"

usage() {
  echo "usage: run-suite.sh SKILL --tier smoke|full|pressure|e2e [--model main|sonnet] [--max-cost-usd N] [--runs N] [--concurrency N] [--case GLOB] [--root DIR] [--allow-tools TOOL...]" >&2
  exit 64
}

[ "$#" -ge 1 ] || usage
skill=$1
shift
tier='' model=main cost='' runs='' jobs='' glob='' root=$(cd "$here/../.." && pwd)
allow=()
while [ "$#" -gt 0 ]; do
  case $1 in
    --tier) tier=${2-}; shift 2 || usage ;;
    --model) model=${2-}; shift 2 || usage ;;
    --max-cost-usd) cost=${2-}; shift 2 || usage ;;
    --runs) runs=${2-}; shift 2 || usage ;;
    --concurrency) jobs=${2-}; shift 2 || usage ;;
    --case) [ -n "${2-}" ] || usage; glob=$2; shift 2 ;;
    --root) root=${2-}; shift 2 || usage ;;
    --allow-tools)
      shift
      while [ "$#" -gt 0 ] && [ "${1#--}" = "$1" ]; do
        allow+=("$1")
        shift
      done
      [ "${#allow[@]}" -gt 0 ] || usage
      ;;
    *) usage ;;
  esac
done
case $tier in smoke | full | pressure | e2e) ;; *) usage ;; esac
case $runs in '') ;; *[!0-9]* | 0) usage ;; esac
[ -z "$runs" ] || [ "$tier" = e2e ] || usage
case $jobs in '' | [1-8]) ;; *) usage ;; esac
[ "$tier" != pressure ] || [ -z "$jobs" ] || usage
model_id=$(od_model_id "$model") || usage

plugin=plugins/overdrive
[ -d "$root/$plugin/evals/$skill" ] || { echo "run-suite: no evals for skill $skill" >&2; exit 1; }
cd "$root" || exit 1

if [ "$tier" = pressure ]; then
  status=0 ran=0
  for dir in "$root/$plugin/evals/$skill/pressure"/*/; do
    [ -d "$dir" ] || continue
    scenario=$(basename "$dir")
    scenario=${scenario#"$skill"-}
    # shellcheck disable=SC2053  # the case glob is meant to be a pattern
    [ -z "$glob" ] || [[ $skill-$scenario == $glob ]] || continue
    ran=1
    args=(--arm with --model "$model" --root "$root")
    [ -z "$cost" ] || args+=(--max-cost-usd "$cost")
    bash "$here/pressure.sh" "$skill" "$scenario" "${args[@]}" || status=$?
  done
  [ "$ran" = 1 ] || { echo "run-suite: no pressure scenario of $skill matches --case $glob" >&2; exit 1; }
  exit "$status"
fi

results_dir=$root/$plugin/evals/results
mkdir -p "$results_dir" || exit 1
json=$results_dir/$skill-$tier.json
rm -f "$json"

args=(plugin eval "$plugin" --trust-plugin --scaffold --no-publish)
judge='' expect=1
case $tier in
  e2e)
    expect=${runs:-3}
    judge=$OD_EVAL_JUDGE
    args+=(--ablation none --runs "$expect" --keep-temp --max-cost-usd "${cost:-30}" --model "$model_id"
      --judge-model "$judge" --json "$json" --tag "$skill-behavior")
    ;;
  smoke)
    args+=(--ablation none --runs 1 --max-cost-usd "${cost:-2}" --model "$model_id" --json "$json" --tag "$skill-smoke")
    ;;
  full)
    expect=3
    judge=$OD_EVAL_JUDGE
    args+=(--ablation with-without --runs 3 --threshold 0.9 --max-cost-usd "${cost:-25}" --model "$model_id"
      --judge-model "$judge" --json "$json" --tag "$skill-trigger" "$skill-behavior")
    ;;
esac
# Parallel runs share one rate limit; the CLI accepts 1 to 8.
[ -z "$jobs" ] || args+=(--concurrency "$jobs")
[ -z "$glob" ] || args+=(--case "$glob")
# Without grants on the command line, the skill's own file grants what its cases need (one per line).
grants=$root/$plugin/evals/$skill/allow-tools
if [ "${#allow[@]}" -eq 0 ] && [ -f "$grants" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    case $line in '' | '#'*) continue ;; esac
    allow+=("$line")
  done < "$grants"
fi
[ "${#allow[@]}" -eq 0 ] || args+=(--allow-tools "${allow[@]}")

od_prepare_env || exit 1

# The summary is the only thing on stdout: CI appends it to the job summary.
claude "${args[@]}" >&2
rc=$?
if [ ! -s "$json" ]; then
  echo "run-suite: claude plugin eval wrote no result (exit $rc)" >&2
  [ "$rc" -ne 0 ] && exit "$rc"
  exit 1
fi

if [ -n "$glob" ] && [ "$(jq -r '.cases | length' "$json")" = 0 ]; then
  echo "run-suite: no eval case matches --case $glob" >&2
  exit 1
fi

summary=$(bash "$here/summarize.sh" --skill "$skill" --tier "$tier" --model "$model_id" --expect-runs "$expect" ${judge:+--judge "$judge"} "$json") || exit 1
printf '%s\n' "$summary"

# A run that errored or never got recorded (either arm) is not evidence, whatever the command exited with.
if [ "$rc" -eq 0 ]; then
  case $summary in
    *'Cases with errored runs: none'*) ;;
    *) echo "run-suite: some runs errored or are missing; treating the suite as failed" >&2; rc=1 ;;
  esac
fi

if [ "$tier" = full ] && [ -z "$glob" ] && [ "$(jq -r '.partial' "$json")" != true ]; then
  printf '%s\n' "$summary" > "$root/$plugin/evals/$skill/RESULTS.md"
fi
exit "$rc"
