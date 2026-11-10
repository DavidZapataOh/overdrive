#!/usr/bin/env bash
# Risk signals: the changes a classification looks at and the items their paths, lines
# and request text raise. Sourced, never executed; needs glob.sh, riskmap.sh and text.sh. Callers
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
# .md .mdx .rst .adoc (any case), and under a docs/ or doc/ directory also plain text,
# images and fonts. Anything else there (a docs site's code and configuration) is code.
# Test files follow the naming conventions of the test runners: *.test.* *.spec.*
# *_test.* *_spec.rb test_*.py test_*.rb *Test(s).java|kt|swift|cs, anything under a
# __tests__/ directory (*Test(s) classes only inside a test directory), JVM sources under
# src/test/ and Rust files under tests/.
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
  if (l ~ /\.(md|mdx|rst|adoc)$/) return 1
  return l ~ /(^|\/)docs?\// && l ~ /\.(txt|png|jpe?g|gif|webp|avif|bmp|ico|svg|woff2?|ttf|otf|eot)$/
}

function has_source_ext(p) {
  return p ~ /\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|rb|java|kt|swift|cs|php)$/
}

function is_test(p,    base) {
  base = p
  sub(/.*\//, "", base)
  if (base ~ /\.(test|spec)\./ || base ~ /_test\./ || base ~ /_spec\.rb$/ || base ~ /^test_.*\.(py|rb)$/) return 1
  if (p ~ /(^|\/)__tests__\//) return 1
  # A *Test class is a test only inside a test directory (src/test/, androidTest/,
  # Tests/AppTests/, Api.Tests/): a LoadTest.java among the sources is product code.
  if (base ~ /Tests?\.(java|kt|swift|cs)$/ && p ~ /(^|\/)([Tt]ests?|[^\/]*Tests?)\//) return 1
  return p ~ /(^|\/)src\/test\/.*\.(java|kts?|scala|groovy)$/ || p ~ /(^|\/)tests\/.*\.rs$/
}

'

# Git output is read without -z: core.quotePath=true C-quotes every unusual path (tab,
# newline, quote, backslash, control or non-ASCII bytes) into one printable field, which
# is lossless and needs no NUL handling (NUL cannot pass through every awk).
# shellcheck disable=SC2016
_OD_SIGNALS_PARSE_AWK='
# An unmerged path has no single content to judge: the classification fails.
function header(s) {
  if (substr(s, 1, 1) != ":" || split(substr(s, 2), h, " ") != 5) { bad = 1; exit }
  om = h[1]; nm = h[2]; sha = h[4]; st = substr(h[5], 1, 1)
  if (st == "U") { printf "unmerged paths\n" > errors; bad = 1; exit }
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
mode == "list" { st = status; om = nm = "000000"; sha = ""; record(unquote($0), ""); next }
{
  header($1)
  if (st == "R" || st == "C") record(unquote($3), unquote($2)); else record(unquote($2), "")
}
END { if (bad) exit 1 }
'

# _signals_git raw|list STATUS DIR WORK SUBCOMMAND ARG...: run a git listing and print
# its records. Untracked pathspecs go to WORK/untracked, git's stderr to WORK/git.err.
_signals_git() {
  local kind=$1 status=$2 dir=$3 work=$4 sub=$5
  shift 5
  git --no-pager -c core.quotePath=true -C "$dir" "$sub" "$@" > "$work/git.out" 2> "$work/git.err" || return
  awk -v mode="$kind" -v status="$status" -v pathspecs="$work/untracked" -v errors="$work/git.err" \
    "$_OD_SIGNALS_LIB_AWK$_OD_SIGNALS_PARSE_AWK" < "$work/git.out"
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
# Returns 65 when a file is invalid and 66 when one cannot be read (riskmap_read), and
# checks every content pattern in one awk run (riskmap_check).
signals_rules() {
  local file source tab=$_SIGNALS_TAB kind pat item lane where records='' lit rest piece
  for file in "$@"; do
    if [ "$file" = "$1" ]; then source=floor; else source=map; fi
    riskmap_read "$file" || return
    [ -n "$_RISKMAP_RECORDS" ] || continue
    while IFS=$tab read -r kind pat item lane where; do
      records=$records$kind$tab$pat$tab$item$tab$lane$tab$where$tab$source$_SIGNALS_NL
    done <<EOF
$_RISKMAP_RECORDS
EOF
  done
  riskmap_check "$records" || return
  while IFS=$tab read -r kind pat item lane where source; do
    [ -n "$kind" ] || continue
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
    else
      printf '%s\t%s\t%s\t%s\t%s\n' "$kind" "$pat" "$item" "$lane" "$source"
    fi
  done <<EOF
$records
EOF
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
  return has_source_ext(base) && base !~ /\.d\.ts$/ && base !~ /\.config\./ && !is_test(p)
}

function dirname(p) {
  return sub(/\/[^\/]*$/, "", p) ? p : ""
}

# stem_of(p): the source file name without its extension.
function stem_of(p) {
  p = basename(p)
  sub(/\.[^.]*$/, "", p)
  return p
}

# test_stem(p): the name test file p is named after (stem.test.ts, stem_test.go,
# test_stem.py, StemTest.java, __tests__/stem.ts, tests/stem.rs).
function test_stem(p,    base) {
  base = basename(p)
  if (match(base, /\.(test|spec)\./) || match(base, /_(test|spec)\./) || match(base, /Tests?\.(java|kt|swift|cs)$/))
    return substr(base, 1, RSTART - 1)
  if (base ~ /^test_.*\.(py|rb)$/) base = substr(base, 6)
  sub(/\.[^.]*$/, "", base)
  return base
}

# A test in a __tests__/ directory sits, for its sources, in the directory above.
function test_dir(p,    d) {
  d = "/" dirname(p) "/"
  while (sub(/\/__tests__\//, "/", d)) ;
  return substr(d, 2, length(d) - 2)
}

function is_manifest(p,    base) {
  base = basename(p)
  return base ~ /^(package\.json|deno\.jsonc?|go\.mod|Cargo\.toml|pyproject\.toml|setup\.py|setup\.cfg|pom\.xml|build\.gradle(\.kts)?|Package\.swift|composer\.json|Gemfile|mix\.exs)$/ ||
    base ~ /\.(csproj|gemspec)$/
}

# package_of(d): the nearest directory at or above d holding a package manifest, "" for
# the repository root.
function package_of(d,    start) {
  start = d
  if (d in pkg_memo) return pkg_memo[d]
  while (d != "" && !(d in pkg)) d = dirname(d)
  return pkg_memo[start] = d
}

function below(d, top) {
  return top == "" ? d : d == top ? "" : substr(d, length(top) + 2)
}

# cover_listed(p): a test of the repository covers the sources named after it in its own
# directory and, when it lives in the test directory of its package (test/ tests/ spec/
# __tests__/ src/test/<lang>/), in the directory it mirrors.
function cover_listed(p,    s, d, top, rel) {
  s = test_stem(p)
  covers["D" SUBSEP test_dir(p) SUBSEP s] = 1
  d = dirname(p); top = package_of(d); rel = below(d, top) "/"
  if (match(rel, /^(src\/test\/[^\/]+|tests?|spec|__tests__)\//)) {
    rel = substr(rel, RLENGTH + 1)
    covers["M" SUBSEP top SUBSEP substr(rel, 1, length(rel) - 1) SUBSEP s] = 1
  }
}

# covered(p): source p has a test in the change (same name in its package, or same
# directory) or one in the repository next to it or mirroring it from its package test
# directory. A source root (src/, lib/, the first directory, src/main/<lang>/) is not mirrored.
function covered(p,    s, d, top, rel) {
  s = stem_of(p); d = dirname(p)
  top = package_of(d)
  if (((top SUBSEP s) in diff_stem) || (d in diff_dir) || (("D" SUBSEP d SUBSEP s) in covers)) return 1
  rel = below(d, top)
  if (("M" SUBSEP top SUBSEP rel SUBSEP s) in covers) return 1
  if (rel == "") return 0
  if (!sub(/^src\/main\/[^\/]+(\/|$)/, "", rel) && !sub(/^[^\/]+(\/|$)/, "", rel)) return 0
  return ("M" SUBSEP top SUBSEP rel SUBSEP s) in covers
}

BEGIN { FS = "\t" }

FILENAME == ARGV[1] {
  if ($1 == "path") {
    npath++; path_re[npath] = $2; path_item[npath] = $3; path_lane[npath] = $4; path_src[npath] = $5
    path_lit[npath] = $6
    # Floors name files whose spelling varies by tool and platform (.Env, dockerfile),
    # so they ignore case; a project map says exactly what it means.
    if ($5 == "floor") { path_re[npath] = tolower($2); path_lit[npath] = tolower($6); path_ci[npath] = 1 }
  } else if ($1 == "pathtoken") {
    ntok++; tok_item[ntok] = $3; tok_lane[ntok] = $4; tok_src[ntok] = $5
    tok_rules[$2] = ($2 in tok_rules) ? tok_rules[$2] " " ntok : ntok
  }
  next
}

# The repository listing, C-quoted by git: its tests and package manifests matter.
FILENAME == ARGV[2] {
  p = unquote($0)
  if (is_test(p)) listed[++nlisted] = p
  else if (is_manifest(p)) pkg[dirname(p)] = 1
  next
}

{
  i = add($4)
  if ($1 == "R" && $5 != "") add($5)
  if ($1 == "L") { link[$5] = 1; next }
  if ($1 == "P") next
  # A test renamed to a non-test name is a test removed; only new paths carry tests.
  if ($1 == "R" && $5 != "" && is_test(unescape($5)) && !is_test(raw[i]))
    hit(index_of[$5], "test-removed", "critical", "computed")
  # Tests and manifests the change adds count as well; packages are resolved at the end.
  if ($1 != "D" && is_test(raw[i])) carried[++ncarried] = raw[i]
  if ($1 != "D" && is_manifest(raw[i])) pkg[dirname(raw[i])] = 1
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
  for (i = 1; i <= npaths; i++) lraw[i] = tolower(raw[i])
  for (r = 1; r <= npath; r++)
    if (path_ci[r]) {
      for (i = 1; i <= npaths; i++)
        if (index(lraw[i], path_lit[r]) && lraw[i] ~ path_re[r]) hit(i, path_item[r], path_lane[r], path_src[r])
    } else {
      for (i = 1; i <= npaths; i++)
        if (index(raw[i], path_lit[r]) && raw[i] ~ path_re[r]) hit(i, path_item[r], path_lane[r], path_src[r])
    }
  if (nsource) for (k = 1; k <= nlisted; k++) cover_listed(listed[k])
  # A test the change carries covers the sources named after it in its package, and
  # every source beside it.
  for (k = 1; k <= ncarried; k++) {
    diff_stem[package_of(dirname(carried[k])) SUBSEP test_stem(carried[k])] = 1
    diff_dir[test_dir(carried[k])] = 1
  }
  for (k = 1; k <= nsource; k++) {
    i = source[k]
    if (!(shown[i] in link) && !covered(raw[i])) hit(i, "untested-change", "critical", "computed")
  }
  for (i = 1; i <= npaths; i++)
    for (k = 1; k <= nhit[i]; k++) print line[i, k]
}
'

# signals_path_items RECORDS RULES LISTING: print item<TAB>lane<TAB>source<TAB>path <p>
# for the items the paths of RECORDS raise under RULES (from signals_rules), and the
# items computed from the changes themselves (deletion, exec-bit, test-removed for a
# deleted test, untested-change), in one awk pass. LISTING names the repository's files
# (git ls-files or ls-tree output) to find the tests and package manifests near a source.
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
  shown = esc(file); doc = is_doc(file); test = is_test(file); manifest = file ~ /(^|\/)package\.json$/
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

# words_of(s): s folded for keyword matching: decomposed accents composed (or dropped),
# then fold() from text.sh: lowercase, accents of Latin-1 letters removed, ñ kept.
function words_of(s) {
  if (index(s, "\314")) {
    gsub("n\314\203", "\303\261", s); gsub("N\314\203", "\303\221", s)
    gsub("\314\200", "", s); gsub("\314\201", "", s); gsub("\314\202", "", s)
    gsub("\314\203", "", s); gsub("\314\210", "", s)
  }
  s = fold(s)
  if (kw_space) gsub(/[[:space:]]+/, " ", s)
  return s
}

# raw_form(w): an expression every unfolded spelling of folded keyword w matches: any
# case, a letter may carry a combining accent or be a two-byte Latin-1 letter, and ñ may
# be decomposed. Lines that miss it are never folded, which is the costly step.
function raw_form(w,    out, i, c, u) {
  out = ""
  for (i = 1; i <= length(w); i++) {
    c = substr(w, i, 1)
    if (c == "\303") { out = out "(\303.|[nN]\314.)"; i++; continue }
    u = toupper(c)
    if (c == " ") c = "[[:space:]]+"
    else if (u != c) c = "([" c u "](\314.)?|\303.)"
    out = out c
  }
  return out
}

# binary(s): a "Binary files A and B differ" line. A file git takes as binary shows no
# lines, so unless its name says it is a binary format, its content went unread.
function binary(s,    i, n, c, b) {
  s = substr(s, 14, length(s) - 20)
  if (s ~ / and \/dev\/null$/) return
  if (substr(s, 1, 14) == "/dev/null and ") b = substr(s, 15)
  else if (substr(s, 1, 1) == "\"") {
    # A quoted old side ends at the first quote that is not escaped.
    n = length(s)
    for (i = 2; i <= n; i++) {
      c = substr(s, i, 1)
      if (c == "\\") i++
      else if (c == "\"") break
    }
    b = substr(s, i + 6)
  } else if (substr(s, length(s)) == "\"") b = substr(s, last(s, " and \"b/") + 5)
  else {
    # Both sides unquoted: same name on both sides unless the file was renamed.
    n = (length(s) - 9) / 2
    if (n == int(n) && substr(s, 3, n) == substr(s, n + 10)) b = substr(s, n + 8)
    else b = substr(s, index(s, " and b/") + 5)
  }
  b = substr(unquote(b), 3)
  if (tolower(b) !~ /\.(png|jpe?g|gif|webp|avif|bmp|ico|icns|tiff?|heic|psd|woff2?|ttf|otf|eot|zip|gz|tgz|bz2|xz|zst|7z|rar|tar|jar|war|mp3|mp4|m4a|wav|ogg|oga|flac|webm|mov|avi|mkv|pdf|wasm|o|a|so|dylib|dll|exe|class|pyc|bin|dat|db|sqlite|lockb|docx|xlsx|pptx|odt|ods)$/)
    hit("unscanned-content", "critical", "computed", "path " esc(b))
}

function last(s, t,    p, q) {
  q = 0
  while ((p = index(substr(s, q + 1), t)) > 0) q += p
  return q
}

function symbols(t, n,    r) {
  for (r = 1; r <= n_symbol; r++)
    if (!((r_item["symbol", r] SUBSEP file) in done_file) && has_symbol(t, r_pat["symbol", r])) line_hit(r, "symbol", n)
}

function added(t, n,    r, l, d) {
  if (is_link) {
    if (substr(t, 1, 1) != "/") t = normalize((index(file, "/") ? substr(file, 1, match(file, "/[^/]*$")) : "") t)
    printf "L\t000000\t000000\t%s\t%s\t\n", esc(t), shown >> records
    return
  }
  if (test && (d = test_case(t))) count(file, d > 0 ? "case+" : "skip+")
  # A package manifest that defines a deploy or release script changes how code ships.
  if (manifest && !(("delivery" SUBSEP file) in done_file) &&
      t ~ /^[[:space:]]*"(vercel-build|deploy|release|predeploy|postdeploy)"[[:space:]]*:/) {
    done_file["delivery" SUBSEP file] = 1
    hit("delivery", "critical", "computed", "line " shown ":" n)
  }
  if (doc) {
    if (secret_any != "" && t ~ secret_any)
      for (r = 1; r <= n_content; r++)
        if (r_item["content", r] == "secrets" && t ~ r_pat["content", r]) line_hit(r, "content", n)
    return
  }
  if (content_any != "" && t ~ content_any)
    for (r = 1; r <= n_content; r++)
      if (!((r_item["content", r] SUBSEP file) in done_file) && t ~ r_pat["content", r]) line_hit(r, "content", n)
  if (n_keyword && t ~ keyword_raw && (l = words_of(t)) ~ keyword_any) {
    for (r = 1; r <= n_keyword; r++)
      if (!((r_item["keyword", r] SUBSEP file) in done_file) && has_word(l, r_pat["keyword", r])) line_hit(r, "keyword", n)
  }
  if (n_symbol && t ~ symbol_any) symbols(t, n)
}

function removed(t, n,    d) {
  if (is_link) return
  if (test && (d = test_case(t))) count(file, d == -1 ? "skip-" : "case-")
  if (!doc && n_symbol && t ~ symbol_any) symbols(t, n)
}

# test_case(t): 1 when line t of a test file declares a test case, -2 when it declares a
# focused case (it runs, every other case is skipped), -1 when it skips cases or focuses a
# suite, 0 otherwise.
# Comments count for nothing; Rust attributes (#[test]) start with # but are not comments.
function test_case(t) {
  if (t ~ /^[[:space:]]*(\/\/|\/\*|\*|<!--|#([^[]|$))/) return 0
  if (t ~ /(^|[^A-Za-z0-9_$])(it|test)(\.[A-Za-z]+)*\.only[.(]/ || t ~ /(^|[^A-Za-z0-9_$.])fit[(]/)
    return -2
  if (t ~ /(^|[^A-Za-z0-9_$])(it|test|describe|context|suite)(\.[A-Za-z]+)*\.(skip|only|skipIf)[.(]/ ||
      t ~ /(^|[^A-Za-z0-9_$.])(xit|xtest|xdescribe|xcontext|fdescribe|fcontext)[(]/ ||
      t ~ /@pytest\.mark\.skip|@unittest\.skip|(^|[^A-Za-z0-9_.])pytest\.skip[(]|(^|[^A-Za-z0-9_])t\.Skip(Now|f)?[(]/ ||
      t ~ /@(Disabled|Ignore)([^A-Za-z0-9_]|$)|#\[ignore|[(,][[:space:]]*Skip[[:space:]]*=/)
    return -1
  if (t ~ /(^|[^A-Za-z0-9_$.])(it|test)[(]|(^|[^A-Za-z0-9_])(def test_|func Test)/ ||
      t ~ /@(Test|ParameterizedTest|RepeatedTest)([^A-Za-z0-9_]|$)|#\[([A-Za-z_]+::)?test([](]|$)/ ||
      t ~ /\[(Fact|Theory|Test|TestMethod|TestCase)([](,]|$)|(^|[^A-Za-z0-9_])func test[A-Z_]/)
    return 1
  return 0
}

# count(f, kind): tally a case line ("case+" added, "case-" removed) or a skip or focus line
# ("skip+", "skip-") of test file f. A removed case or focused case is a case gone; an added
# skip or focus stops cases, unless it replaces one removed (a skipped case renamed); a
# removed skip gives no credit, since that case was not running.
function count(f, kind) {
  if (!(f in cases)) { cases[f] = 0; case_file[++n_case_file] = f }
  tally[f, kind]++
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
      r_shown[r] = $2
      r_pat[$1, r] = words_of($2)
      p = r_pat[$1, r]
      keyword_raw = keyword_raw (keyword_raw == "" ? "" : "|") raw_form(p)
      gsub(/ /, "[[:space:]]+", p)
      keyword_any = keyword_any (keyword_any == "" ? "" : "|") p
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
/^Binary files .* differ$/ { binary($0); next }
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
        hit(r_item["keyword", r], r_lane["keyword", r], r_src["keyword", r], "keyword \"" r_shown[r] "\"")
  }
  for (k = 1; k <= n_case_file; k++) {
    f = case_file[k]
    gone = tally[f, "case-"] + (tally[f, "skip+"] > tally[f, "skip-"] ? tally[f, "skip+"] - tally[f, "skip-"] : 0)
    if (gone > tally[f, "case+"] + 0) hit("test-removed", "critical", "computed", "path " esc(f))
  }
}
'

# _signals_unreadable DIR WORK: write to WORK/skip the git pathspecs that exclude the
# tracked paths changed since HEAD that are now a socket, FIFO or device: git cannot
# hash them and aborts the whole patch, and they have no content to scan. Their path
# is still classified from the raw records. Untracked ones are never listed by git.
_signals_unreadable() {
  local dir=$1 p
  git --no-pager -C "$dir" diff --name-only -z --no-relative --no-ext-diff HEAD -- > "$2/changed" || return
  : > "$2/skip"
  while IFS= read -r -d '' p; do
    if [ -e "$dir/$p" ] && [ ! -f "$dir/$p" ] && [ ! -L "$dir/$p" ] && [ ! -d "$dir/$p" ]; then
      printf ':(exclude,literal)%s\0' "$p" >> "$2/skip"
    fi
  done < "$2/changed"
}

# _signals_patch_head WORK GIT_ARG...: diff against HEAD without the paths in WORK/skip.
_signals_patch_head() {
  local work=$1 p
  shift
  set -- "$@" HEAD --
  while IFS= read -r -d '' p; do set -- "$@" "$p"; done < "$work/skip"
  # The exclusions are pathspec magic: user settings must not turn them into literals.
  GIT_LITERAL_PATHSPECS=0 GIT_ICASE_PATHSPECS=0 git "$@"
}

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
      _signals_unreadable "$dir" "$work" || return
      if [ ! -s "$work/untracked" ]; then
        _signals_patch_head "$work" "$@"
        return
      fi
      index=$(git -C "$dir" rev-parse --git-path index) || return
      case $index in /* | [A-Za-z]:*) ;; *) index=$dir/$index ;; esac
      if [ -f "$index" ]; then cp "$index" "$work/index" || return; fi
      GIT_INDEX_FILE=$work/index GIT_LITERAL_PATHSPECS=1 git -C "$dir" add -N --pathspec-from-file=- \
        < "$work/untracked" || return
      GIT_INDEX_FILE=$work/index _signals_patch_head "$work" "$@"
      ;;
    *) return 2 ;;
  esac
}

# signals_content RULES RECORDS [INTENT]: read a -U0 patch on stdin and print
# item<TAB>lane<TAB>source<TAB>evidence for the content, keyword and symbol rules of
# RULES, for test files that lose test cases (test-removed), and for keywords in the
# request text INTENT. Symlink targets are appended to RECORDS as "L" records.
signals_content() {
  OD_RECORDS=$2 OD_INTENT=${3:-} awk "$_OD_SIGNALS_LIB_AWK$OD_FOLD_AWK$_OD_SIGNALS_CONTENT_AWK" "$1" -
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
