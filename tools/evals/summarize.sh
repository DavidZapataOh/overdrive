#!/usr/bin/env bash
# Usage: summarize.sh [--skill NAME] [--tier TIER] [--model ID] [--judge ID] RESULT.json
# Renders the aggregate-result.json written by `claude plugin eval --json` as Markdown.

set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
. "$here/lib.sh"

skill='' tier='' model='' judge=''
while [ "$#" -gt 0 ]; do
  case $1 in
    --skill) skill=${2-}; shift 2 || break ;;
    --tier) tier=${2-}; shift 2 || break ;;
    --model) model=${2-}; shift 2 || break ;;
    --judge) judge=${2-}; shift 2 || break ;;
    -*) echo "summarize: unknown option: $1" >&2; exit 64 ;;
    *) break ;;
  esac
done
if [ "$#" -ne 1 ]; then
  echo "usage: summarize.sh [--skill NAME] [--tier TIER] [--model ID] [--judge ID] RESULT.json" >&2
  exit 64
fi
file=$1
[ -f "$file" ] || { echo "summarize: no such file: $file" >&2; exit 1; }
version=$(jq -r '.schemaVersion // empty' "$file" 2>/dev/null)
[ "$version" = 1 ] || { echo "summarize: $file is not an aggregate result with schemaVersion 1" >&2; exit 1; }

buckets=$(
  jq -r '.cases[] | select(.dir | test("/trigger/")) | .dir | split("/") | last' "$file" |
    while IFS= read -r name; do
      printf '%s %s\n' "$name" "$(od_split_bucket "$name")"
    done |
    jq -Rn '[inputs | split(" ") | { (.[0]): .[1] }] | add // {}'
)

jq -r --argjson buckets "$buckets" --arg skill "$skill" --arg tier "$tier" --arg model "$model" --arg judge "$judge" '
  def rounded($places): (. * $places | round) / $places;
  def pad2: tostring | if length < 2 then "0" + . else . end;
  def f2:
    if rounded(100) < 0 then "-" + (-. | f2)
    else (. * 100 | round) as $c | "\($c / 100 | floor).\($c % 100 | pad2)" end;
  def signed:
    rounded(100) as $r | if $r > 0 then "+" + f2 elif $r < 0 then f2 else "0.00" end;
  def usd:
    if . >= 0.01 then "$" + f2
    else (. * 10000 | round) as $c | "$0.\($c | tostring | ("0000" + .)[-4:])" end;
  def pct($c; $n): (100 * $c / $n | round | tostring) + "%";

  def tier_of:
    if (.dir | test("/trigger/")) then "trigger"
    elif (.dir | test("/behavior/")) then "behavior"
    elif (.dir | test("/pressure/")) then "pressure"
    else "other" end;
  def two_arm: (.arms.without | length) > 0;
  def has_delta: two_arm and ((.aggregates.delta // null) != null);
  def regressed: has_delta and ((.aggregates.delta | rounded(100)) < 0);
  def case_cost: [.arms.with[], .arms.without[]] | map((.costUsd // 0) + (.judgeCostUsd // 0)) | add // 0;
  def trigger_stats:
    (.graders | map(select(.type == "tool_used" and .config.tool == "Skill")) | .[0]) as $g
    | if $g == null then { neg: false, n: 0, fired: 0, correct: false, none: true }
      else (($g.config.max // null) == 0) as $neg
        | [ .arms.with[] | (.graders | map(select(.name == $g.name)) | .[0]) as $r
            | select($r != null) | if $neg then ($r.passed | not) else $r.passed end ] as $runs
        | ($runs | length) as $n
        | ($runs | map(select(.)) | length) as $fired
        | { neg: $neg, n: $n, fired: $fired, none: false,
            correct: ($n > 0 and (if $neg then $fired / $n < 0.5 else $fired / $n > 0.5 end)) }
      end;

  . as $doc
  | [ .cases[] | . + { tier: tier_of, base: (.dir | split("/") | last) } ] as $cases
  | [ $cases[] | select(.tier == "trigger")
      | . + { trig: trigger_stats }
      | . + { bucket: ($buckets[.base] // "validation") } ] as $triggers
  | [ $cases[] | select(regressed) ] as $regressions
  | def accuracy($split; $floor):
      [ $triggers[] | select(.bucket == $split) ] as $set
      | if ($set | length) == 0 then "- Trigger accuracy (\($split)): none"
        else ($set | map(select(.trig.correct)) | length) as $ok
          | ($set | length) as $n
          | "- Trigger accuracy (\($split)): \($ok)/\($n) (\(pct($ok; $n)))"
            + (if $floor then ", floor 90%: " + (if $ok / $n >= 0.9 then "PASS" else "FAIL" end) else "" end)
        end;
    [ "# Eval results: \(if $skill == "" then "suite" else $skill end)",
      "",
      "- Date: \($doc.startedAt[0:10])",
      "- Claude Code: \($doc.claudeVersion)",
      (if $tier != "" then "- Tier: \($tier)" else empty end),
      (if $model != "" then "- Agent model: \($model)" else empty end),
      (if $judge != "" then "- Judge model: \($judge)" else empty end),
      (if $doc.partial == true then "- Partial: yes (\($doc.partialReason // "unknown")), not comparable with complete runs" else empty end),
      "- Suite: score \(($doc.aggregates.overallScore // 0) | f2), mean delta \(if ($doc.aggregates.meanDelta // null) == null then "n/a" else ($doc.aggregates.meanDelta | signed) end), cases passed \($doc.aggregates.casesPassed)/\($doc.aggregates.casesTotal), cost \(($doc.costUsd // 0) | usd), \($doc.durationSeconds // 0)s",
      "- Cases with negative delta: " + (if ($regressions | length) == 0 then "none" else "\($regressions | length) (\($regressions | map(.name) | join(", ")))" end),
      "",
      "## Trigger accuracy",
      "",
      accuracy("train"; false),
      accuracy("validation"; true),
      "",
      "## Cases",
      "",
      "| Case | Tier | With | Without | Delta | Runs | Cost | Notes |",
      "| --- | --- | --- | --- | --- | --- | --- | --- |",
      ( $cases[] | . as $c
        | (if $c.tier == "trigger" then ($triggers[] | select(.name == $c.name) | .trig) else null end) as $t
        | ( [ (if $t == null then empty
               elif $t.none then "no Skill grader"
               else "\(if $t.neg then "negative" else "positive" end): fired \($t.fired)/\($t.n)" end),
              (if ($c | regressed) then "REGRESSION" else empty end)
            ] | join("; ") ) as $notes
        | "| \($c.name) | \($c.tier) | \(($c.aggregates.score // 0) | f2) | \(if ($c | two_arm) and (($c.aggregates.scoreWithout // null) != null) then ($c.aggregates.scoreWithout | f2) else "n/a" end) | \(if ($c | has_delta) then ($c.aggregates.delta | signed) else "n/a" end) | \($c.arms.with | length) | \($c | case_cost | usd) | \($notes) |" )
    ] | .[]
' "$file"
