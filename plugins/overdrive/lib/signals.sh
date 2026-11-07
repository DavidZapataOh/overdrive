#!/usr/bin/env bash
# Risk signals: the changes a classification looks at and the items their paths, lines
# and request text raise. Sourced, never executed; needs glob.sh and riskmap.sh. Callers
# export LC_ALL=C so that bytes, not characters, are compared everywhere.
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

# Functions shared by the awk programs below.
# Documentation files are prose about a subject, not the subject itself: names ending in
# .md .mdx .rst .adoc (any case), and every file under a docs/ or doc/ directory.
# Test files follow the naming conventions of the test runners: *.test.* *.spec.*
# *_test.* test_*.py and anything under a __tests__/ directory.
# shellcheck disable=SC2016
_OD_SIGNALS_LIB_AWK='
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
  return l ~ /\.(md|mdx|rst|adoc)$/ || l ~ /(^|\/)docs?\//
}

function is_test(p,    base) {
  base = p
  sub(/.*\//, "", base)
  return base ~ /\.(test|spec)\./ || base ~ /_test\./ || base ~ /^test_.*\.py$/ || p ~ /(^|\/)__tests__\//
}

'

# Git output is parsed by one awk program in two forms. With -z, NULs become newlines
# when no path holds a newline (the output then has none at all): fields are counted
# from each header's status, so a path that looks like a header is still read as a path.
# Otherwise git is asked again without -z, where core.quotePath=true C-quotes every
# unusual path into printable ASCII. NUL itself cannot pass through every awk.
# shellcheck disable=SC2016
_OD_SIGNALS_PARSE_AWK='
function header(s) {
  if (substr(s, 1, 1) != ":" || split(substr(s, 2), h, " ") != 5) { bad = 1; exit }
  om = h[1]; nm = h[2]; sha = h[4]; st = substr(h[5], 1, 1)
}

# Untracked files are also written as C-quoted pathspecs (git reads that quoting back),
# so that their content can be diffed; a name ending in / is a nested repository.
function record(path, old,    e, n, part, i, q) {
  e = esc(path)
  printf "%s\t%s\t%s\t%s\t%s\t%s\n", st, om, nm, e, esc(old), sha
  if (st == "?" && substr(path, length(path)) != "/") {
    n = split(e, part, "\"")
    q = part[1]
    for (i = 2; i <= n; i++) q = q "\\\"" part[i]
    printf "\"%s\"\n", q > pathspecs
  }
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
# its records. Untracked pathspecs go to WORK/untracked, git's stderr to WORK/git.err.
_signals_git() {
  local kind=$1 status=$2 dir=$3 work=$4 sub=$5 lines
  shift 5
  git --no-pager -c core.quotePath=true -C "$dir" "$sub" -z "$@" > "$work/git.out" 2> "$work/git.err" || return
  lines=$(wc -l < "$work/git.out") || return
  if [ "$lines" -eq 0 ]; then
    tr '\000' '\n' < "$work/git.out" |
      awk -v mode="$kind" -v status="$status" -v quoted=0 -v pathspecs="$work/untracked" "$_OD_SIGNALS_LIB_AWK$_OD_SIGNALS_PARSE_AWK"
  else
    git --no-pager -c core.quotePath=true -C "$dir" "$sub" "$@" > "$work/git.out" 2> "$work/git.err" || return
    awk -v mode="$kind" -v status="$status" -v quoted=1 -v pathspecs="$work/untracked" \
      "$_OD_SIGNALS_LIB_AWK$_OD_SIGNALS_PARSE_AWK" < "$work/git.out"
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
  : > "$work/untracked"
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
}

# signals_named_paths P...: print a record for each path named by the caller.
signals_named_paths() {
  local p
  for p in "$@"; do
    _signals_escape "$p"
    printf 'P\t000000\t000000\t%s\t\t\n' "$_SIGNALS_ESC"
  done
}

# signals_rules FLOORS [MAP...]: print the rules of FLOORS and each MAP as
# kind<TAB>pattern<TAB>item<TAB>lane<TAB>source[<TAB>literal], source being floor or map,
# with path globs compiled to anchored EREs once here so the matcher never sees a glob.
# A path rule also carries the longest literal run of its glob, which every matching
# path contains: a substring test rules most paths out before the expression runs.
# Returns riskmap_load's status (65 invalid, 66 unreadable) when a file fails.
signals_rules() {
  local file source tab=$_SIGNALS_TAB kind pat item lane rest records lit piece
  for file in "$@"; do
    if [ "$file" = "$1" ]; then source=floor; else source=map; fi
    records=$(riskmap_load "$file") || return
    [ -n "$records" ] || continue
    while IFS=$tab read -r kind pat item lane rest; do
      if [ "$kind" = path ]; then
        lit=''
        # **/ may match nothing, its slash included, so it splits like a wildcard.
        rest=${pat//\*\*\//*}
        while [ -n "$rest" ]; do
          piece=${rest%%[*?]*}
          [ "${#piece}" -le "${#lit}" ] || lit=$piece
          [ "$piece" != "$rest" ] || break
          rest=${rest#*[*?]}
        done
        _glob_compile "$pat"
        printf 'path\t%s\t%s\t%s\t%s\t%s\n' "$_GLOB_RE" "$item" "$lane" "$source" "$lit"
        continue
      fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$pat" "$item" "$lane" "$source"
    done <<EOF
$records
EOF
  done
}

# Path tokens skip documentation files; path globs still apply to them.
# shellcheck disable=SC2016
_OD_SIGNALS_PATHS_AWK='
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

function basename(p) {
  sub(/.*\//, "", p)
  return p
}

# Source files whose changes need a test: these extensions, minus declaration files,
# tool configuration and the tests themselves.
function is_source(p,    base) {
  base = basename(p)
  return base ~ /\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|rb|java|kt|swift|cs|php)$/ &&
    base !~ /\.d\.ts$/ && base !~ /\.config\./ && !is_test(p)
}

# test_stems(p): register the names a test file is named after (stem.test.*,
# stem.spec.*, test_stem.py, stem_test.*, __tests__/stem.*).
function test_stems(p,    base, s) {
  base = basename(p)
  if (match(base, /\.(test|spec)\./)) stem[substr(base, 1, RSTART - 1)] = 1
  if (match(base, /_test\./)) stem[substr(base, 1, RSTART - 1)] = 1
  if (base ~ /^test_.*\.py$/) stem[substr(base, 6, length(base) - 8)] = 1
  if (p ~ /(^|\/)__tests__\//) { s = base; sub(/\.[^.]*$/, "", s); stem[s] = 1 }
}

BEGIN { FS = "\t" }

FILENAME == ARGV[1] {
  if ($1 == "path") {
    npath++; path_re[npath] = $2; path_item[npath] = $3; path_lane[npath] = $4; path_src[npath] = $5
    path_lit[npath] = $6
  } else if ($1 == "pathtoken") {
    ntok++; tok_item[ntok] = $3; tok_lane[ntok] = $4; tok_src[ntok] = $5
    tok_rules[$2] = ($2 in tok_rules) ? tok_rules[$2] " " ntok : ntok
  }
  next
}

# The repository listing, C-quoted by git: only its test files matter.
FILENAME == ARGV[2] {
  p = unquote($0)
  if (is_test(p)) test_stems(p)
  next
}

{
  i = add($4)
  if ($1 == "R" && $5 != "") add($5)
  if ($1 == "L") { link[$5] = 1; next }
  if ($1 == "P") next
  if (is_test(raw[i]) || ($5 != "" && is_test(unescape($5)))) tests_changed = 1
  if ($1 == "D") {
    hit(i, is_test(raw[i]) ? "test-removed" : "deletion", is_test(raw[i]) ? "critical" : "standard", "computed")
    next
  }
  if ($3 == "100755" && $2 != "100755" && $2 != "000000") hit(i, "exec-bit", "standard", "computed")
  if ($3 != "120000" && is_source(raw[i])) source[++nsource] = i
}

# Globs are matched rule by rule over all paths: awks such as gawk keep only the last
# dynamic regex compiled at each call site, so alternating rules per path would compile
# every rule once per path. (Their union as one expression is slower still: anchored
# alternatives defeat the fast matchers.)
END {
  for (r = 1; r <= npath; r++)
    for (i = 1; i <= npaths; i++)
      if (index(raw[i], path_lit[r]) && raw[i] ~ path_re[r]) hit(i, path_item[r], path_lane[r], path_src[r])
  # A change that carries no test file is untested unless a test is named after the file.
  if (!tests_changed)
    for (k = 1; k <= nsource; k++) {
      i = source[k]
      s = basename(raw[i])
      sub(/\.[^.]*$/, "", s)
      if (!(s in stem) && !(shown[i] in link)) hit(i, "untested-change", "critical", "computed")
    }
  for (i = 1; i <= npaths; i++)
    for (k = 1; k <= nhit[i]; k++) print line[i, k]
}
'

# signals_path_items RECORDS RULES LISTING: print item<TAB>lane<TAB>source<TAB>path <p>
# for the items the paths of RECORDS raise under RULES (from signals_rules), and the
# items computed from the changes themselves (deletion, exec-bit, test-removed for a
# deleted test, untested-change), in one awk pass. LISTING names the repository's files
# (git ls-files or ls-tree output) to find the tests named after a source file.
# Renames are judged by both paths: moving a file out of auth/ is an auth change.
# Named paths (P) are plans rather than changes, so nothing is computed from them.
signals_path_items() {
  awk "$_OD_SIGNALS_LIB_AWK$_OD_SIGNALS_PATHS_AWK" "$2" "$3" "$1"
}

# The changed lines are read from one -U0 patch stream. Hunk headers give the line counts,
# so a changed line that itself looks like a header is never taken for one. Content rules
# are tried only on lines that match their union, one expression compiled once, and each
# item is reported once per file, at its first line. Documentation files are read for
# secrets only; binary files show no lines at all. Keyword and symbol rules are likewise
# tried only on lines that match their union. A symlink's line is its target, which
# becomes an "L" record appended to RECORDS.
# shellcheck disable=SC2016
_OD_SIGNALS_CONTENT_AWK='
function path_of(s) {
  sub(/\t$/, "", s)
  if (s == "/dev/null") return ""
  return substr(unquote(s), 3)
}

function start_file() {
  file = ""; oldp = ""; newp = ""; is_link = 0
}

function set_file() {
  file = (newp != "") ? newp : oldp
  shown = esc(file); doc = is_doc(file); test = is_test(file)
}

function hunk(s,    f, a, n) {
  split(s, f, " ")
  n = split(substr(f[2], 2), a, ","); oln = a[1] + 0; orem = (n > 1) ? a[2] + 0 : 1
  n = split(substr(f[3], 2), a, ","); nln = a[1] + 0; nrem = (n > 1) ? a[2] + 0 : 1
}

function hit(item, lane, source, evidence,    key) {
  key = item SUBSEP evidence
  if (key in done) return
  done[key] = 1
  printf "%s\t%s\t%s\t%s\n", item, lane, source, evidence
}

function line_hit(r, kind, n) {
  if ((r_item[kind, r] SUBSEP file) in done_file) return
  done_file[r_item[kind, r] SUBSEP file] = 1
  hit(r_item[kind, r], r_lane[kind, r], r_src[kind, r], "line " shown ":" n)
}

# A word byte is an ASCII letter, digit or underscore, or any non-ASCII byte (part of
# a letter such as ñ); keywords are lowercase, so is the text they are looked for in.
function word_byte(c) {
  return c ~ /[a-z0-9_]/ || (c != "" && !index(ascii, c))
}

function has_word(s, w,    p, len) {
  len = length(w)
  while ((p = index(s, w)) > 0) {
    if ((p == 1 || !word_byte(substr(s, p - 1, 1))) && !word_byte(substr(s, p + len, 1))) return 1
    s = substr(s, p + 1)
  }
  return 0
}

function has_symbol(s, w,    p, len) {
  len = length(w)
  while ((p = index(s, w)) > 0) {
    if ((p == 1 || substr(s, p - 1, 1) !~ /[A-Za-z0-9_$]/) && substr(s, p + len, 1) !~ /[A-Za-z0-9_$]/) return 1
    s = substr(s, p + 1)
  }
  return 0
}

function words_of(s) {
  s = tolower(s)
  if (kw_space) gsub(/[[:space:]]+/, " ", s)
  return s
}

function symbols(t, n,    r) {
  for (r = 1; r <= n_symbol; r++)
    if (!((r_item["symbol", r] SUBSEP file) in done_file) && has_symbol(t, r_pat["symbol", r])) line_hit(r, "symbol", n)
}

function added(t, n,    r, l) {
  if (is_link) {
    if (substr(t, 1, 1) != "/") t = normalize((index(file, "/") ? substr(file, 1, match(file, "/[^/]*$")) : "") t)
    printf "L\t000000\t000000\t%s\t%s\t\n", esc(t), shown >> records
    return
  }
  if (test && t ~ /(^|[^A-Za-z0-9_$.])(it|test)[(]|(^|[^A-Za-z0-9_])(def test_|func Test)/) count(file, 1)
  if (doc) {
    if (secret_any != "" && t ~ secret_any)
      for (r = 1; r <= n_content; r++)
        if (r_item["content", r] == "secrets" && t ~ r_pat["content", r]) line_hit(r, "content", n)
    return
  }
  if (content_any != "" && t ~ content_any)
    for (r = 1; r <= n_content; r++)
      if (!((r_item["content", r] SUBSEP file) in done_file) && t ~ r_pat["content", r]) line_hit(r, "content", n)
  if (n_keyword && t ~ keyword_any) {
    l = words_of(t)
    for (r = 1; r <= n_keyword; r++)
      if (!((r_item["keyword", r] SUBSEP file) in done_file) && has_word(l, r_pat["keyword", r])) line_hit(r, "keyword", n)
  }
  if (n_symbol && t ~ symbol_any) symbols(t, n)
}

function removed(t, n) {
  if (is_link) return
  if (test && t ~ /(^|[^A-Za-z0-9_$.])(it|test)[(]|(^|[^A-Za-z0-9_])(def test_|func Test)/) count(file, -1)
  if (!doc && n_symbol && t ~ symbol_any) symbols(t, n)
}

# any_case(w): an expression for keyword w in any ASCII case, its spaces matching any
# run of whitespace; a line that does not match it cannot hold the keyword.
function any_case(w,    out, i, c) {
  out = ""
  for (i = 1; i <= length(w); i++) {
    c = substr(w, i, 1)
    if (c ~ /[a-z]/) c = "[" c toupper(c) "]"
    else if (c == " ") c = "[[:space:]]+"
    out = out c
  }
  return out
}

# count(f, d): test cases added (d = 1) or removed (d = -1) in test file f.
function count(f, d) {
  if (!(f in cases)) { cases[f] = 0; case_file[++n_case_file] = f }
  if (d > 0) cases_added[f]++; else cases_removed[f]++
}

# normalize(p): p with . and .. segments and repeated slashes resolved lexically.
function normalize(p,    n, seg, i, k, out) {
  n = split(p, seg, "/"); k = 0
  for (i = 1; i <= n; i++) {
    if (seg[i] == "" || seg[i] == ".") continue
    if (seg[i] == ".." && k > 0 && st[k] != "..") { k--; continue }
    st[++k] = seg[i]
  }
  out = ""
  for (i = 1; i <= k; i++) out = out (i > 1 ? "/" : "") st[i]
  return out
}

BEGIN {
  FS = "\t"
  records = ENVIRON["OD_RECORDS"]
  for (i = 1; i < 128; i++) ascii = ascii sprintf("%c", i)
}

FILENAME == ARGV[1] {
  if ($1 == "content" || $1 == "keyword" || $1 == "symbol") {
    r = ++n_rule[$1]
    r_pat[$1, r] = $2; r_item[$1, r] = $3; r_lane[$1, r] = $4; r_src[$1, r] = $5
    if ($1 == "content") {
      content_any = content_any (content_any == "" ? "" : "|") "(" $2 ")"
      if ($3 == "secrets") secret_any = secret_any (secret_any == "" ? "" : "|") "(" $2 ")"
    }
    if ($1 == "keyword") {
      keyword_any = keyword_any (keyword_any == "" ? "" : "|") any_case($2)
      if (index($2, " ")) kw_space = 1
    }
    # Identifiers hold only letters, digits, _ and $, and $ is the one to bracket.
    if ($1 == "symbol") { p = $2; gsub(/[$]/, "[$]", p); symbol_any = symbol_any (symbol_any == "" ? "" : "|") p }
  }
  n_content = n_rule["content"]; n_keyword = n_rule["keyword"]; n_symbol = n_rule["symbol"]
  next
}

orem > 0 || nrem > 0 {
  c = substr($0, 1, 1)
  if (c == "+") { nrem--; added(substr($0, 2), nln++) }
  else if (c == "-") { orem--; removed(substr($0, 2), oln++) }
  else if (c == " ") { orem--; nrem--; oln++; nln++ }
  else if (c != "\\") { bad = 1; exit }
  next
}
/^diff --git / { start_file(); next }
/^@@ / { hunk($0); next }
/^--- / { oldp = path_of(substr($0, 5)); next }
/^\+\+\+ / { newp = path_of(substr($0, 5)); set_file(); next }
/^(new file mode|new mode) 120000$/ || /^index [0-9a-f]+\.\.[0-9a-f]+ 120000$/ { is_link = 1 }

END {
  if (bad || orem > 0 || nrem > 0) exit 1
  if (n_keyword && ENVIRON["OD_INTENT"] != "") {
    l = ENVIRON["OD_INTENT"]
    kw_space = 1
    l = words_of(l)
    for (r = 1; r <= n_keyword; r++)
      if (has_word(l, r_pat["keyword", r]))
        hit(r_item["keyword", r], r_lane["keyword", r], r_src["keyword", r], "keyword \"" r_pat["keyword", r] "\"")
  }
  for (k = 1; k <= n_case_file; k++) {
    f = case_file[k]
    if (cases_removed[f] + 0 > cases_added[f] + 0) hit("test-removed", "critical", "computed", "path " esc(f))
  }
}
'

# signals_patch GIT_DIR WORK MODE [ARG...]: print the -U0 patch of one mode (diff RANGE,
# staged or worktree). In worktree mode, untracked files (WORK/untracked, written by
# signals_changes) are added as intent-to-add entries to a copy of the index, so that
# git diffs them as new files, binary detection included; the real index is never written.
signals_patch() {
  local dir=$1 work=$2 mode=$3 index
  shift 3
  # Every option that changes which lines are printed, or how, is pinned.
  set -- --no-pager -c core.quotePath=true -C "$dir" diff -U0 --no-color --no-ext-diff \
    --no-textconv --src-prefix=a/ --dst-prefix=b/ -M --no-relative --ignore-submodules=none \
    --submodule=short "$@"
  case $mode in
    diff) git "$@" -- ;;
    staged) git "$@" --cached -- ;;
    worktree)
      if [ ! -s "$work/untracked" ]; then
        git "$@" HEAD --
        return
      fi
      index=$(git -C "$dir" rev-parse --git-path index) || return
      case $index in /* | [A-Za-z]:*) ;; *) index=$dir/$index ;; esac
      if [ -f "$index" ]; then cp "$index" "$work/index" || return; fi
      GIT_INDEX_FILE=$work/index GIT_LITERAL_PATHSPECS=1 git -C "$dir" add -N --pathspec-from-file=- \
        < "$work/untracked" || return
      GIT_INDEX_FILE=$work/index git "$@" HEAD --
      ;;
    *) return 2 ;;
  esac
}

# signals_content RULES RECORDS [INTENT]: read a -U0 patch on stdin and print
# item<TAB>lane<TAB>source<TAB>evidence for the content, keyword and symbol rules of
# RULES, for test files that lose test cases (test-removed), and for keywords in the
# request text INTENT. Symlink targets are appended to RECORDS as "L" records.
signals_content() {
  OD_RECORDS=$2 OD_INTENT=${3:-} awk "$_OD_SIGNALS_LIB_AWK$_OD_SIGNALS_CONTENT_AWK" "$1" -
}

# signals_listing GIT_DIR MODE [RANGE]: print the repository's file names, C-quoted, as
# of the end of RANGE (diff) or the index (staged, worktree).
signals_listing() {
  local dir=$1 end
  case $2 in
    diff)
      end=${3##*..}
      git --no-pager -c core.quotePath=true -C "$dir" ls-tree -r --name-only --full-tree "${end:-HEAD}"
      ;;
    *) git --no-pager -c core.quotePath=true -C "$dir" ls-files ;;
  esac
}
