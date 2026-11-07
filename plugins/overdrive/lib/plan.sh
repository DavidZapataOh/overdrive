#!/usr/bin/env bash
# Plan parsing shared by brief and overlap. Sourced, never executed.
# A task runs from its "### Task N:" heading to the next "### Task " or a level one
# or two heading; headings inside fenced code blocks count as text, so plans can quote
# markdown. Plans written one task per heading in the earlier format parse unchanged.

if [ -n "${_OD_PLAN_LOADED:-}" ]; then return 0; fi
_OD_PLAN_LOADED=1

# shellcheck source=text.sh
. "${BASH_SOURCE[0]%/*}/text.sh"

# shellcheck disable=SC2016
_PLAN_AWK='
# Backticked spans outside parentheses: the annotations after a path, such as
# (job `ci`), are not paths, while parentheses inside a span are part of it.
function paths(line,   i, c, depth, inq, span) {
  depth = 0; inq = 0
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    if (inq) {
      if (c == "`") { inq = 0; if (depth == 0) keep(span) }
      else span = span c
    } else if (c == "`") { inq = 1; span = "" }
    else if (c == "(") depth++
    else if (c == ")" && depth > 0) depth--
  }
}
function keep(p) {
  sub(/^[ \t]+/, "", p); sub(/[ \t]+$/, "", p)
  sub(/:[0-9]+(-[0-9]+)?$/, "", p)
  sub(/^\.\//, "", p)
  if (p == "" || (p in seenpath)) return
  seenpath[p] = 1
  print p
}
{
  line = $0
  sub(/\r$/, "", line)
  if (fence(line) || infence) { if (on) emit($0, line); next }
  if (done) next
  if (substr(line, 1, 9) == "### Task " || line ~ /^##? /) {
    # Keep reading after the section ends: a fence left open further down is still an error.
    if (on) { on = 0; done = 1; next }
    if (mode != "constraints" && substr(line, 1, length(head)) == head) { on = 1; found = 1; emit($0, line); next }
    if (mode == "constraints" && line ~ /^## Global Constraints[ \t]*$/) { on = 1; found = 1; next }
    next
  }
  if (on) emit($0, line)
}
function emit(raw, line) {
  if (mode == "files") {
    if (!infence && line ~ /^[ \t]*[-*][ \t]+(Create|Modify|Test):/) paths(line)
    return
  }
  # Hold blank lines back so the section never ends in one.
  if (line ~ /^[ \t]*$/) { blank[++nb] = raw; return }
  if (printed) for (k = 1; k <= nb; k++) print blank[k]
  nb = 0; printed = 1
  print raw
}
END {
  if (infence) {
    printf "overdrive: %s:%d: unclosed code fence opened at line %d\n", FILENAME, fline, fline > "/dev/stderr"
    exit 3
  }
  exit !found
}
'

# _plan_run MODE FILE [N]: run the parser; exit 1 when the section is missing, 2 when
# FILE is unreadable, 3 when a code fence never closes.
_plan_run() {
  [ -r "$2" ] || return 2
  PLAN_MODE=$1 PLAN_HEAD="### Task ${3-}:" LC_ALL=C awk \
    'BEGIN { mode = ENVIRON["PLAN_MODE"]; head = ENVIRON["PLAN_HEAD"] }'"$OD_FENCE_AWK$_PLAN_AWK" "$2"
}

# plan_task FILE N: print task N verbatim, heading included.
plan_task() { _plan_run task "$1" "$2"; }

# plan_global_constraints FILE: print the body of the Global Constraints section.
plan_global_constraints() { _plan_run constraints "$1"; }

# plan_task_files FILE N: print the paths task N creates, modifies or tests, one per
# line, in order, without duplicates or :line ranges.
plan_task_files() { _plan_run files "$1" "$2"; }
