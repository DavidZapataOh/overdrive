#!/usr/bin/env bash
# Risk map parser. Sourced, never executed. Grammar: docs/risk-map.md.

if [ -n "${_OD_RISKMAP_LOADED:-}" ]; then return 0; fi
_OD_RISKMAP_LOADED=1

# Records are buffered so that an invalid map yields no rules at all: a partial
# map would let the classifier under-classify.
# shellcheck disable=SC2016
_OD_RISKMAP_AWK='
function fail(reason) {
  printf "invalid rule at %s:%d: %s\n", src, NR, reason > "/dev/stderr"
  bad = 1
}

# tokenize(s): split s into tok[1..n]; returns n, or -1 with terr set.
function tokenize(s,    n, i, len, c, d, t, closed) {
  n = 0; i = 1; len = length(s)
  while (1) {
    while (i <= len && ((c = substr(s, i, 1)) == " " || c == "\t")) i++
    if (i > len) break
    if (c == "#") break
    if (c == "\"") {
      t = ""; closed = 0; i++
      while (i <= len) {
        c = substr(s, i, 1)
        if (c == "\\" && i < len && ((d = substr(s, i + 1, 1)) == "\"" || d == "\\")) {
          t = t d; i += 2; continue
        }
        if (c == "\"") { closed = 1; i++; break }
        t = t c; i++
      }
      if (!closed) { terr = "unterminated quote"; return -1 }
      if (i <= len && (c = substr(s, i, 1)) != " " && c != "\t") {
        terr = "unexpected character after closing quote"; return -1
      }
    } else {
      match(substr(s, i), /^[^ \t]+/)
      t = substr(s, i, RLENGTH); i += RLENGTH
    }
    tok[++n] = t
  }
  return n
}

# bracket_end(s, i): index of the "]" closing the bracket expression opened at i, or 0.
function bracket_end(s, i,    len, c, k) {
  len = length(s); i++
  if (substr(s, i, 1) == "^") i++
  if (substr(s, i, 1) == "]") i++
  while (i <= len) {
    c = substr(s, i, 1)
    if (c == "]") return i
    if (c == "[" && index(":=.", substr(s, i + 1, 1)) > 0) {
      k = index(substr(s, i + 2), substr(s, i + 1, 1) "]")
      if (k == 0) return 0
      i += k + 3
      continue
    }
    i++
  }
  return 0
}

# portable_ere(s): s with interval expressions expanded and literal braces
# bracketed, because older mawk and BSD awk lack intervals; "" with eerr on error.
function portable_ere(s,    out, len, i, c, d, j, depth, atom, lo, hi, iv, k, rep) {
  out = ""; len = length(s); i = 1; depth = 0; atom = 0
  while (i <= len) {
    c = substr(s, i, 1)
    if (c == "\\") {
      if (i == len) { eerr = "trailing backslash"; return "" }
      d = substr(s, i + 1, 1)
      if (d ~ /[A-Za-z0-9]/) { eerr = "non-portable escape \047\\" d "\047"; return "" }
      atom = length(out) + 1
      out = out ((d == "{" || d == "}") ? "[" d "]" : c d)
      i += 2
      continue
    }
    if (c == "[") {
      j = bracket_end(s, i)
      if (j == 0) { eerr = "unterminated bracket expression"; return "" }
      atom = length(out) + 1
      out = out substr(s, i, j - i + 1)
      i = j + 1
      continue
    }
    if (c == "(") {
      stack[++depth] = length(out) + 1
      out = out c; atom = 0; i++
      continue
    }
    if (c == ")") {
      if (depth == 0) { eerr = "unbalanced parenthesis"; return "" }
      atom = stack[depth--]
      out = out c; i++
      continue
    }
    if (c == "{" && match(substr(s, i), /^\{[0-9]+(,[0-9]*)?\}/)) {
      iv = substr(s, i + 1, RLENGTH - 2); i += RLENGTH
      if (!atom) { eerr = "repetition without an operand"; return "" }
      k = index(iv, ",")
      lo = (k ? substr(iv, 1, k - 1) : iv) + 0
      hi = k ? (k == length(iv) ? -1 : substr(iv, k + 1) + 0) : lo
      if (lo > 255 || hi > 255 || (hi >= 0 && hi < lo)) { eerr = "invalid repetition bounds"; return "" }
      rep = substr(out, atom); out = substr(out, 1, atom - 1)
      for (k = 0; k < lo; k++) out = out rep
      if (hi < 0) out = out rep "*"
      else for (k = lo; k < hi; k++) out = out rep "?"
      atom = 0
      continue
    }
    if (c == "{" || c == "}") {
      atom = length(out) + 1
      out = out "[" c "]"; i++
      continue
    }
    if (c == "|" || c == "^" || c == "$" || c == "*" || c == "+" || c == "?") atom = 0
    else atom = length(out) + 1
    out = out c; i++
  }
  if (depth > 0) { eerr = "unbalanced parenthesis"; return "" }
  return out
}

function valid_keyword(s,    i, c) {
  if (s == "") return 0
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c != " " && index(punct, c) > 0) return 0
  }
  return 1
}

BEGIN {
  src = ENVIRON["OD_RISKMAP_SOURCE"]
  punct = "!\"#$%&\047()*+,-./:;<=>?@[\\]^`{|}~"
  kinds = " path pathtoken keyword symbol content "
}

{
  line = $0
  if (NR == 1 && substr(line, 1, 3) == "\357\273\277") line = substr(line, 4)
  sub(/\r$/, "", line)
  n = tokenize(line)
  if (n < 0) { fail(terr); next }
  if (n == 0) next
  kind = tok[1]; pat = tok[2]; item = tok[3]; lane = (n >= 4) ? tok[4] : "critical"
  if (index(kinds, " " kind " ") == 0) { fail("unknown kind \047" kind "\047 (path, pathtoken, keyword, symbol or content)"); next }
  if (n < 2) { fail("missing pattern"); next }
  if (n < 3) { fail("missing item"); next }
  if (n > 4) { fail("unexpected field \047" tok[5] "\047"); next }
  if (pat == "") { fail("empty pattern"); next }
  if (index(pat, "\t") > 0) { fail("pattern contains a tab"); next }
  if (item !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) { fail("invalid item \047" item "\047 (lowercase letters and digits joined by single hyphens)"); next }
  if (lane != "critical" && lane != "standard") { fail("unknown lane \047" lane "\047 (critical or standard)"); next }
  if (kind == "path") {
    if (substr(pat, 1, 1) == "/") { fail("path glob must be relative to the repository root"); next }
  } else if (kind == "pathtoken") {
    if (pat ~ /[\/._ -]/) { fail("path token cannot contain / . _ - or spaces"); next }
    pat = tolower(pat)
  } else if (kind == "keyword") {
    gsub(/  +/, " ", pat); sub(/^ /, "", pat); sub(/ $/, "", pat)
    if (!valid_keyword(pat)) { fail("keyword must be words of letters, digits and underscores"); next }
    pat = tolower(pat)
  } else if (kind == "symbol") {
    if (pat !~ /^[A-Za-z_$][A-Za-z0-9_$]*$/) { fail("symbol must be an identifier"); next }
  } else {
    eerr = ""
    pat = portable_ere(pat)
    if (eerr != "") { fail("invalid regular expression: " eerr); next }
    if (pat == "") { fail("empty pattern"); next }
  }
  rec[++nrec] = kind "\t" pat "\t" item "\t" lane "\t" src ":" NR
}

END {
  if (bad) exit 65
  for (r = 1; r <= nrec; r++) print rec[r]
}
'

# riskmap_load FILE: print FILE as normalized records
# kind<TAB>pattern<TAB>item<TAB>lane<TAB>FILE:line; exit 65 on any invalid rule.
riskmap_load() {
  if [ ! -f "$1" ] || [ ! -r "$1" ]; then
    printf 'cannot read risk map: %s\n' "$1" >&2
    return 66
  fi
  # C locale: byte semantics and ASCII case folding behave the same in every awk.
  OD_RISKMAP_SOURCE=$1 LC_ALL=C awk "$_OD_RISKMAP_AWK" < "$1"
}
