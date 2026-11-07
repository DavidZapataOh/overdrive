#!/usr/bin/env bash
# Risk signals: the changes a classification looks at and the items their paths raise.
# Sourced, never executed; needs common.sh, glob.sh and riskmap.sh. Callers export
# LC_ALL=C so that bytes, not characters, are compared everywhere.
#
# A change record is one line: status<TAB>oldmode<TAB>newmode<TAB>path<TAB>oldpath.
# status is git's raw letter (A C D M R T U X), "?" for an untracked file or "P" for a
# path named by the caller; modes are git's (000000 when absent or unknown); oldpath is
# set for renames and copies only. Paths are escaped so that any file name fits on one
# line: backslash, tab, newline and carriage return become \\ \t \n \r.

if [ -n "${_OD_SIGNALS_LOADED:-}" ]; then return 0; fi
_OD_SIGNALS_LOADED=1

_SIGNALS_ESC=
printf -v _SIGNALS_TAB '\t'
printf -v _SIGNALS_NL '\n'
printf -v _SIGNALS_CR '\r'

# _signals_escape PATH: set _SIGNALS_ESC to PATH escaped for a record. Builtins only:
# it runs once per path.
_signals_escape() {
  local s=$1 out='' c bs="\\" tab=$_SIGNALS_TAB nl=$_SIGNALS_NL cr=$_SIGNALS_CR
  case $s in
    *"$bs"* | *"$tab"* | *"$nl"* | *"$cr"*) ;;
    *) _SIGNALS_ESC=$s; return 0 ;;
  esac
  while [ -n "$s" ]; do
    c=${s:0:1}
    s=${s:1}
    case $c in
      "$bs") out=$out"\\\\" ;;
      "$tab") out=$out'\t' ;;
      "$nl") out=$out'\n' ;;
      "$cr") out=$out'\r' ;;
      *) out=$out$c ;;
    esac
  done
  _SIGNALS_ESC=$out
}

# _signals_raw FILE: print records for the output of git diff --raw -z in FILE, in
# bash. Only used when a path holds a newline; see _signals_parse.
_signals_raw() {
  local h st om nm p q
  while IFS= read -r -d '' h; do
    case $h in :*) ;; *) return 1 ;; esac
    h=${h#:}
    om=${h%% *} h=${h#* }
    nm=${h%% *} h=${h#* }
    h=${h#* } h=${h#* }
    st=${h:0:1}
    IFS= read -r -d '' p || return 1
    q=''
    case $st in
      R | C)
        q=$p
        IFS= read -r -d '' p || return 1
        _signals_escape "$q"
        q=$_SIGNALS_ESC
        ;;
    esac
    _signals_escape "$p"
    printf '%s\t%s\t%s\t%s\t%s\n' "$st" "$om" "$nm" "$_SIGNALS_ESC" "$q"
  done < "$1"
}

# _signals_list STATUS FILE: print a record for each NUL-terminated path in FILE, in bash.
_signals_list() {
  local p
  while IFS= read -r -d '' p; do
    _signals_escape "$p"
    printf '%s\t000000\t000000\t%s\t\n' "$1" "$_SIGNALS_ESC"
  done < "$2"
}

# The same parsing as _signals_raw and _signals_list, for NUL-terminated fields turned
# into lines. Fields are counted from each header's status, so a path that looks like a
# header is still read as a path.
# shellcheck disable=SC2016
_OD_SIGNALS_PARSE_AWK='
# gsub replacements treat backslashes differently across awks, so escape by hand.
function esc(s,    out, i, n, c) {
  if (!index(s, "\\") && !index(s, "\t") && !index(s, "\r")) return s
  out = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") c = "\\\\"; else if (c == "\t") c = "\\t"; else if (c == "\r") c = "\\r"
    out = out c
  }
  return out
}
mode == "list" { printf "%s\t000000\t000000\t%s\t\n", status, esc($0); next }
want == 0 {
  if (substr($0, 1, 1) != ":" || split(substr($0, 2), h, " ") != 5) { bad = 1; exit }
  om = h[1]; nm = h[2]; st = substr(h[5], 1, 1)
  want = (st == "R" || st == "C") ? 2 : 1; old = ""
  next
}
want == 2 { old = esc($0); want = 1; next }
{ printf "%s\t%s\t%s\t%s\t%s\n", st, om, nm, esc($0), old; want = 0 }
END { if (bad || want) exit 1 }
'

# _signals_parse raw|list STATUS FILE: print the records of a -z git output. NUL cannot
# pass through every awk, so NULs become newlines when no path holds a newline (the
# file has none at all), and bash reads the fields otherwise. A bash read loop is too
# slow for the common case: reading 10,000 paths takes seconds.
_signals_parse() {
  local lines
  [ -s "$3" ] || return 0
  lines=$(wc -l < "$3") || return
  if [ "$lines" -eq 0 ]; then
    tr '\000' '\n' < "$3" | awk -v mode="$1" -v status="$2" "$_OD_SIGNALS_PARSE_AWK"
  elif [ "$1" = raw ]; then
    _signals_raw "$3"
  else
    _signals_list "$2" "$3"
  fi
}

# signals_changes GIT_DIR WORK MODE [ARG...]: print the change records of one mode.
#   diff RANGE   committed changes in A..B or A...B (works in a bare repository)
#   staged       the index against HEAD
#   worktree     the working tree against HEAD, plus untracked files
#   paths P...   the given repository-relative paths, as they are named
# GIT_DIR is the directory git runs in (the top level of a working tree, or a bare
# repository); WORK is a scratch directory. Git's stderr is left in WORK/git.err.
# Returns non-zero when git fails, so callers can fail closed.
signals_changes() {
  local dir=$1 work=$2 mode=$3
  shift 3
  if [ "$mode" = paths ]; then
    signals_named_paths "$@"
    return
  fi
  # Options that change the raw format or the paths it prints are pinned, so user
  # configuration cannot alter what is classified.
  set -- --no-pager -C "$dir" diff --raw -z -M --no-color --no-ext-diff --no-relative \
    --ignore-submodules=none "$@"
  case $mode in
    diff) git "$@" -- > "$work/git.out" 2> "$work/git.err" || return ;;
    staged) git "$@" --cached -- > "$work/git.out" 2> "$work/git.err" || return ;;
    worktree) git "$@" HEAD -- > "$work/git.out" 2> "$work/git.err" || return ;;
    *) return 2 ;;
  esac
  _signals_parse raw '' "$work/git.out" || return
  if [ "$mode" = worktree ]; then
    git -C "$dir" ls-files -o --exclude-standard -z > "$work/git.out" 2> "$work/git.err" || return
    _signals_parse list '?' "$work/git.out"
  fi
}

# signals_named_paths P...: print a record for each path named by the caller.
signals_named_paths() {
  local p
  for p in "$@"; do
    _signals_escape "$p"
    printf 'P\t000000\t000000\t%s\t\n' "$_SIGNALS_ESC"
  done
}

# signals_rules FLOORS [MAP]: print the rules of FLOORS and MAP as
# kind<TAB>pattern<TAB>item<TAB>lane<TAB>source, source being floor or map, with path
# globs compiled to anchored EREs once here so the matcher never sees a glob.
# Returns riskmap_load's status (65 invalid, 66 unreadable) when a file fails.
signals_rules() {
  local file source tab=$_SIGNALS_TAB kind pat item lane rest records
  for file in "$@"; do
    if [ "$file" = "$1" ]; then source=floor; else source=map; fi
    records=$(riskmap_load "$file") || return
    [ -n "$records" ] || continue
    while IFS=$tab read -r kind pat item lane rest; do
      if [ "$kind" = path ]; then
        _glob_compile "$pat"
        pat=$_GLOB_RE
      fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$pat" "$item" "$lane" "$source"
    done <<EOF
$records
EOF
  done
}

# Documentation files are prose about a subject, not the subject itself, so path tokens
# skip them: names ending in .md .mdx .rst .txt .adoc (any case), and every file under
# the repository's top-level docs/ directory. Path globs still apply to them.
# Test files follow the naming conventions of the test runners: *.test.* *.spec.*
# *_test.* test_*.py and anything under a __tests__/ directory.
# shellcheck disable=SC2016
_OD_SIGNALS_PATHS_AWK='
function unescape(s,    out, i, n, c) {
  if (index(s, "\\") == 0) return s
  out = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\" && i < n) {
      c = substr(s, ++i, 1)
      if (c == "t") c = "\t"; else if (c == "n") c = "\n"; else if (c == "r") c = "\r"
    }
    out = out c
  }
  return out
}

function is_doc(p,    l) {
  l = tolower(p)
  return l ~ /\.(md|mdx|rst|txt|adoc)$/ || substr(l, 1, 5) == "docs/"
}

function is_test(p,    base) {
  base = p
  sub(/.*\//, "", base)
  return base ~ /\.(test|spec)\./ || base ~ /_test\./ || base ~ /^test_.*\.py$/ || p ~ /(^|\/)__tests__\//
}

function hit(i, item, lane, source,    key) {
  key = item SUBSEP i
  if (key in done) return
  done[key] = 1
  line[i, ++nhit[i]] = item "\t" lane "\t" source "\tpath " shown[i]
}

# add(s): register a path once and apply the token rules, which are hash lookups.
function add(s,    i, n, k, r, t, list) {
  if (s in index_of) return index_of[s]
  i = index_of[s] = ++npaths
  shown[i] = s
  raw[i] = unescape(s)
  if (ntok == 0 || is_doc(raw[i])) return i
  n = split(tolower(raw[i]), seg, "[/._-]")
  for (k = 1; k <= n; k++) {
    t = seg[k]
    if (!(t in tok_rules)) continue
    split(tok_rules[t], list, " ")
    for (r = 1; r in list; r++) hit(i, tok_item[list[r]], tok_lane[list[r]], tok_src[list[r]])
  }
  return i
}

BEGIN { FS = "\t" }

FILENAME == ARGV[1] {
  if ($1 == "path") {
    npath++; path_re[npath] = $2; path_item[npath] = $3; path_lane[npath] = $4; path_src[npath] = $5
  } else if ($1 == "pathtoken") {
    ntok++; tok_item[ntok] = $3; tok_lane[ntok] = $4; tok_src[ntok] = $5
    tok_rules[$2] = ($2 in tok_rules) ? tok_rules[$2] " " ntok : ntok
  }
  next
}

{
  i = add($4)
  if ($1 == "R" && $5 != "") add($5)
  if ($1 == "D" && !is_test(raw[i])) hit(i, "deletion", "standard", "computed")
  if ($3 == "100755" && $2 != "100755" && $2 != "000000") hit(i, "exec-bit", "standard", "computed")
}

# Globs are matched rule by rule over all paths: awks such as gawk keep only the last
# dynamic regex compiled at each call site, so alternating rules per path would compile
# every rule once per path.
END {
  for (r = 1; r <= npath; r++)
    for (i = 1; i <= npaths; i++)
      if (raw[i] ~ path_re[r]) hit(i, path_item[r], path_lane[r], path_src[r])
  for (i = 1; i <= npaths; i++)
    for (k = 1; k <= nhit[i]; k++) print line[i, k]
}
'

# signals_path_items RECORDS RULES: print item<TAB>lane<TAB>source<TAB>path <p> for the
# items the paths of RECORDS raise under RULES (from signals_rules), in one awk pass.
# Renames are judged by both paths: moving a file out of auth/ is an auth change.
signals_path_items() {
  awk "$_OD_SIGNALS_PATHS_AWK" "$2" "$1"
}
