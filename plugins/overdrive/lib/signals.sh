#!/usr/bin/env bash
# Risk signals: the changes a classification looks at and the items their paths raise.
# Sourced, never executed; needs common.sh, glob.sh and riskmap.sh. Callers export
# LC_ALL=C so that bytes, not characters, are compared everywhere.
#
# A change record is one line: status<TAB>oldmode<TAB>newmode<TAB>path<TAB>oldpath<TAB>newsha.
# status is git's raw letter (A C D M R T U X), "?" for an untracked file, "P" for a
# path named by the caller or "L" for the target of a symlink (oldpath = the link);
# modes are git's (000000 when absent or unknown); oldpath is set for renames, copies
# and link targets; newsha is git's object id of the new side (zeros when git did not
# hash it, empty when there is none). Paths are escaped so that any file name fits on one
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

# Git output is parsed by one awk program in two forms. With -z, NULs become newlines
# when no path holds a newline (the output then has none at all): fields are counted
# from each header's status, so a path that looks like a header is still read as a path.
# Otherwise git is asked again without -z, where core.quotePath=true C-quotes every
# unusual path into printable ASCII. NUL itself cannot pass through every awk.
# shellcheck disable=SC2016
_OD_SIGNALS_PARSE_AWK='
# gsub replacements treat backslashes differently across awks, so escape by hand.
function esc(s,    out, i, n, c) {
  if (!index(s, "\\") && !index(s, "\t") && !index(s, "\n") && !index(s, "\r")) return s
  out = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") c = "\\\\"
    else if (c == "\t") c = "\\t"
    else if (c == "\n") c = "\\n"
    else if (c == "\r") c = "\\r"
    out = out c
  }
  return out
}

function unquote(s,    out, i, n, c) {
  if (substr(s, 1, 1) != "\"") return s
  s = substr(s, 2, length(s) - 2); out = ""; n = length(s)
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1)
    if (c == "\\") {
      c = substr(s, ++i, 1)
      if (c ~ /[0-7]/) {
        c = sprintf("%c", c * 64 + substr(s, i + 1, 1) * 8 + substr(s, i + 2, 1))
        i += 2
      }
      else if (c == "t") c = "\t"; else if (c == "n") c = "\n"; else if (c == "r") c = "\r"
      else if (c == "a") c = "\007"; else if (c == "b") c = "\010"; else if (c == "f") c = "\014"
      else if (c == "v") c = "\013"
    }
    out = out c
  }
  return out
}

function header(s) {
  if (substr(s, 1, 1) != ":" || split(substr(s, 2), h, " ") != 5) { bad = 1; exit }
  om = h[1]; nm = h[2]; sha = h[4]; st = substr(h[5], 1, 1)
}

# Symlinks are judged by their target as well; untracked files have no mode here.
function record(path, old) {
  printf "%s\t%s\t%s\t%s\t%s\t%s\n", st, om, nm, esc(path), esc(old), sha
  if ((nm == "120000" && st != "D") || st == "?") printf "%s\t%s\n", (sha == "" ? "-" : sha), esc(path) > links
}

BEGIN { FS = "\t" }
mode == "list" { st = status; om = nm = "000000"; sha = ""; record(quoted ? unquote($0) : $0, ""); next }
quoted {
  header($1)
  if (st == "R" || st == "C") record(unquote($3), unquote($2)); else record(unquote($2), "")
  next
}
want == 0 { header($0); want = (st == "R" || st == "C") ? 2 : 1; old = ""; next }
want == 2 { old = $0; want = 1; next }
{ record($0, old); want = 0 }
END { if (bad || want) exit 1 }
'

# _signals_git raw|list STATUS DIR WORK SUBCOMMAND ARG...: run a git listing and print
# its records. Link candidates go to WORK/links, git's stderr to WORK/git.err.
_signals_git() {
  local kind=$1 status=$2 dir=$3 work=$4 sub=$5 lines
  shift 5
  git --no-pager -c core.quotePath=true -C "$dir" "$sub" -z "$@" > "$work/git.out" 2> "$work/git.err" || return
  lines=$(wc -l < "$work/git.out") || return
  if [ "$lines" -eq 0 ]; then
    tr '\000' '\n' < "$work/git.out" |
      awk -v mode="$kind" -v status="$status" -v quoted=0 -v links="$work/links" "$_OD_SIGNALS_PARSE_AWK"
  else
    git --no-pager -c core.quotePath=true -C "$dir" "$sub" "$@" > "$work/git.out" 2> "$work/git.err" || return
    awk -v mode="$kind" -v status="$status" -v quoted=1 -v links="$work/links" \
      "$_OD_SIGNALS_PARSE_AWK" < "$work/git.out"
  fi
}

# _signals_unescape TEXT: set _SIGNALS_ESC to a record path turned back into the name.
_signals_unescape() {
  local s=$1 out='' c
  case $s in *"\\"*) ;; *) _SIGNALS_ESC=$s; return 0 ;; esac
  while [ -n "$s" ]; do
    c=${s:0:1}
    s=${s:1}
    if [ "$c" = "\\" ]; then
      c=${s:0:1}
      s=${s:1}
      case $c in
        t) c=$_SIGNALS_TAB ;;
        n) c=$_SIGNALS_NL ;;
        r) c=$_SIGNALS_CR ;;
      esac
    fi
    out=$out$c
  done
  _SIGNALS_ESC=$out
}

# _signals_links DIR WORK: print an "L" record for the target of each link candidate,
# read from the object when git hashed it and from the working tree otherwise. The
# target is resolved against the link's directory, so it names a repository path.
_signals_links() {
  local dir=$1 work=$2 sha p name target base
  [ -s "$work/links" ] || return 0
  while IFS=$_SIGNALS_TAB read -r sha p; do
    _signals_unescape "$p"
    name=$_SIGNALS_ESC
    # A zero id is a working tree file git did not hash; "-" is an untracked file.
    case $sha in
      - | *[!0]*) ;;
      *) sha=- ;;
    esac
    if [ "$sha" != - ]; then
      target=$(git -C "$dir" cat-file blob "$sha" 2> "$work/git.err") || return
    elif [ -L "$dir/$name" ]; then
      target=$(readlink "$dir/$name") || return
    else
      continue
    fi
    case $target in
      /*) ;;
      *)
        base=''
        case $name in */*) base=${name%/*}/ ;; esac
        _od_normalize_path "$base$target"
        target=$_OD_PATH
        ;;
    esac
    _signals_escape "$target"
    printf 'L\t000000\t000000\t%s\t%s\t\n' "$_SIGNALS_ESC" "$p"
  done < "$work/links"
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
  : > "$work/links"
  # Options that change the raw format or the paths it prints are pinned, so user
  # configuration cannot alter what is classified.
  set -- diff --raw --no-abbrev -M --no-color --no-ext-diff --no-relative --ignore-submodules=none "$@"
  case $mode in
    diff) _signals_git raw '' "$dir" "$work" "$@" -- || return ;;
    staged) _signals_git raw '' "$dir" "$work" "$@" --cached -- || return ;;
    worktree)
      _signals_git raw '' "$dir" "$work" "$@" HEAD -- || return
      _signals_git list '?' "$dir" "$work" ls-files -o --exclude-standard || return
      ;;
    *) return 2 ;;
  esac
  _signals_links "$dir" "$work"
}

# signals_named_paths P...: print a record for each path named by the caller.
signals_named_paths() {
  local p
  for p in "$@"; do
    _signals_escape "$p"
    printf 'P\t000000\t000000\t%s\t\t\n' "$_SIGNALS_ESC"
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
  n = split(raw[i], seg, "[/._-]")
  for (k = 1; k <= n; k++) {
    token(i, tolower(seg[k]))
    if (seg[k] ~ /[a-z][A-Z]|[A-Z][A-Z][a-z]|[A-Za-z][0-9]|[0-9][A-Za-z]/) words(i, seg[k])
  }
  return i
}

function token(i, t,    r, list) {
  if (!(t in tok_rules)) return
  split(tok_rules[t], list, " ")
  for (r = 1; r in list; r++) hit(i, tok_item[list[r]], tok_lane[list[r]], tok_src[list[r]])
}

# words(i, s): the words of an identifier-like segment, split where a lowercase letter
# meets an uppercase one, before the last capital of a run followed by lowercase
# (OAuthToken: O Auth Token) and between letters and digits (oauth2: oauth 2).
function words(i, s,    n, k, c, q, w, kind, prev) {
  n = length(s); w = ""; prev = ""
  for (k = 1; k <= n; k++) {
    c = substr(s, k, 1)
    kind = (c ~ /[a-z]/) ? "l" : (c ~ /[A-Z]/) ? "u" : (c ~ /[0-9]/) ? "d" : "o"
    q = (k < n) ? substr(s, k + 1, 1) : ""
    if (w != "" && ((prev == "l" && kind == "u") || (prev == "u" && kind == "u" && q ~ /[a-z]/) ||
        (prev == "d" && (kind == "l" || kind == "u")) || ((prev == "l" || prev == "u") && kind == "d"))) {
      token(i, tolower(w)); w = ""
    }
    w = w c; prev = kind
  }
  if (w != "") token(i, tolower(w))
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
