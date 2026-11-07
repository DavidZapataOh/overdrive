#!/usr/bin/env bash
# Tests for the role agents.

root=$(dirname "$(dirname "$RUNNER")")
agents_dir="$root/plugins/overdrive/agents"
. "$root/tools/lib/skillmeta.sh"

names="builder reviewer critical-reviewer final-reviewer researcher"

# body FILE: everything after the closing frontmatter delimiter.
body() { awk 'NR == 1 { next } !done && $0 == "---" { done = 1; next } done' "$1"; }

# expect NAME MODEL EFFORT MAXTURNS TOOLS ("-" = key absent)
expect() {
  f="$agents_dir/$1.md"
  assert_eq "$1" "$(fm_get "$f" name)"
  assert_eq "$2" "$(fm_get "$f" model)"
  assert_eq "$3" "$(fm_get "$f" effort)"
  assert_eq "$4" "$(fm_get "$f" maxTurns)"
  if [ "$5" = "-" ]; then
    if fm_get "$f" tools >/dev/null; then echo "$1 must not restrict tools" >&2; return 1; fi
  else
    assert_eq "$5" "$(fm_get "$f" tools)"
  fi
}

test_every_agent_sets_model_and_effort() {
  for n in $names; do [ -f "$agents_dir/$n.md" ] || { echo "missing $n.md" >&2; return 1; }; done
  ro="Read, Grep, Glob, Bash"
  expect builder sonnet high 120 -
  expect reviewer sonnet high 40 "$ro"
  expect critical-reviewer opus high 60 "$ro"
  expect final-reviewer opus xhigh 80 "$ro"
  expect researcher sonnet medium 80 "Read, Grep, Glob, Bash, WebFetch, WebSearch"
}

test_reviewers_are_read_only_tools() {
  for n in reviewer critical-reviewer final-reviewer; do
    t=$(fm_get "$agents_dir/$n.md" tools)
    case ", $t," in *", Edit,"* | *", Write,"* | *", NotebookEdit,"*) echo "$n can edit" >&2; return 1 ;; esac
  done
}

test_descriptions_under_200_chars() {
  for n in $names; do
    d=$(fm_get "$agents_dir/$n.md" description)
    c=$(chars_of "$d")
    [ "$c" -gt 0 ] && [ "$c" -le 200 ] || { echo "$n description is $c chars" >&2; return 1; }
    case "$d" in *"Overdrive"*"brief"* | *"Overdrive"*"package"*) ;; *) echo "$n description lacks dispatch note" >&2; return 1 ;; esac
  done
}

test_no_agent_mentions_dispatching_agents_except_prohibition() {
  for n in $names; do
    hits=$(body "$agents_dir/$n.md" | grep -iE 'dispatch|spawn|subagent|delegate' || true)
    [ -n "$hits" ] || { echo "$n lacks the prohibition" >&2; return 1; }
    printf '%s\n' "$hits" | grep -viE 'never|do not|must not' && { echo "$n mentions dispatching outside a prohibition" >&2; return 1; }
  done
  return 0
}

has() { # NAME STRING
  case "$(body "$agents_dir/$1.md")" in *"$2"*) ;; *) echo "$1 lacks: $2" >&2; return 1 ;; esac
}

test_every_body_names_the_report_contract() {
  for n in $names; do
    has "$n" 'Status: DONE'
    has "$n" 'Ruling: <what> — <why> — <cost if wrong>'
    has "$n" 'Your first action is to read the'
    has "$n" 'BLOCKED'
  done
  for n in builder reviewer critical-reviewer final-reviewer; do has "$n" 'at most 15 lines'; done
  has reviewer 'Status: DONE | BLOCKED'
  has builder 'Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT'
  has researcher 'Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT'
  has researcher '2,000 tokens'
  has researcher 'N of M'
}

test_agents_with_bash_only_write_own_output_files() {
  # shellcheck disable=SC2016
  for n in reviewer critical-reviewer final-reviewer researcher; do
    has "$n" 'Bash may create your own output files under `.overdrive/run/`'
    has "$n" 'never modify repository files'
  done
}

test_critical_and_final_reviewers_use_ledger_and_evidence() {
  has critical-reviewer 'overdrive evidence list'
  has critical-reviewer 'once'
  has final-reviewer 'Rulings made'
  has final-reviewer 'overdrive ledger rulings'
}

test_reviewers_name_the_findings_format() {
  line='F<n> | P0..P3 | 0|25|50|75|100 | path:line | title | "verbatim quote" | failure mode | fix | plan-mandated:yes|no'
  for n in reviewer critical-reviewer final-reviewer; do
    b=$(body "$agents_dir/$n.md")
    for s in "$line" '.overdrive/run/reviews/<base7>-<head7>.findings' 'overdrive findings check' 'F1 | P1 | 75 |' 'verbatim' 'Do not run the test suite'; do
      case "$b" in *"$s"*) ;; *) echo "$n lacks: $s" >&2; return 1 ;; esac
    done
  done
}

test_builder_names_its_cli_and_stop_rules() {
  b=$(body "$agents_dir/builder.md")
  for s in 'overdrive pin PATH...' 'overdrive evidence red -- CMD...' 'overdrive evidence green -- CMD...' 'overdrive pin --release "REASON"' 'overdrive pin --clear' '10 minutes'; do
    case "$b" in *"$s"*) ;; *) echo "builder lacks: $s" >&2; return 1 ;; esac
  done
}

test_no_agent_references_plans_or_tasks() {
  for n in $names; do
    if grep -qiE 'sprint|plan task|task [0-9]' "$agents_dir/$n.md"; then echo "$n has a forbidden reference" >&2; return 1; fi
  done
}

# bin/ is not on an agent's PATH, so an agent that runs the CLI takes its path from the brief.
# shellcheck disable=SC2016  # backquotes are literal Markdown
test_cli_users_take_the_path_from_the_brief() {
  for n in $names; do
    body "$agents_dir/$n.md" | grep -q '`overdrive [a-z]' || continue
    has "$n" '`Overdrive CLI:`'
  done
}
