#!/usr/bin/env bash
# awk building blocks shared by the markdown readers. Sourced, never executed.
# Programs that use them run under LC_ALL=C, so every awk sees bytes the same way.

if [ -n "${_OD_TEXT_LOADED:-}" ]; then return 0; fi
_OD_TEXT_LOADED=1

# fence(line): true for a line that opens or closes a fenced code block; infence holds
# the state and fline the line that opened the block, so callers can fail loudly on a
# block that never closes instead of silently swallowing the rest of the file.
# shellcheck disable=SC2016,SC2034
OD_FENCE_AWK='
function fence(line,   t) {
  if (line !~ /^[ \t]*(```|~~~)/) return 0
  t = line; sub(/^[ \t]*/, "", t)
  if (!infence) {
    fch = substr(t, 1, 1); flen = match(t, /[^`~]|$/) - 1
    # A backtick fence whose info string holds a backtick is inline code.
    if (fch == "`" && index(substr(t, flen + 1), "`")) return 0
    infence = 1; fline = FNR; return 1
  }
  if (substr(t, 1, 1) == fch && t ~ /^(`+|~+)[ \t\r]*$/ && length(t) >= flen) infence = 0
  return 1
}
'

# fold(s): lowercase s and drop the accents of Latin-1 letters written in UTF-8, so
# "DECISIÓN", "Decisión" and "decision" compare equal without depending on a locale.
# Ñ only lowercases: it is a letter of its own, not an accented N.
# shellcheck disable=SC2034
OD_FOLD_AWK='
function foldinit(   pairs, n, i) {
  n = split("\303\200 a \303\201 a \303\202 a \303\203 a \303\204 a \303\205 a \303\207 c \303\210 e \303\211 e \303\212 e \303\213 e \303\214 i \303\215 i \303\216 i \303\217 i \303\221 \303\261 \303\222 o \303\223 o \303\224 o \303\225 o \303\226 o \303\231 u \303\232 u \303\233 u \303\234 u \303\240 a \303\241 a \303\242 a \303\243 a \303\244 a \303\245 a \303\247 c \303\250 e \303\251 e \303\252 e \303\253 e \303\254 i \303\255 i \303\256 i \303\257 i \303\262 o \303\263 o \303\264 o \303\265 o \303\266 o \303\271 u \303\272 u \303\273 u \303\274 u", pairs, " ")
  for (i = 1; i < n; i += 2) { nfold++; foldfrom[nfold] = pairs[i]; foldto[nfold] = pairs[i + 1] }
}
function fold(s,   i) {
  s = tolower(s)
  if (!index(s, "\303")) return s
  if (!nfold) foldinit()
  for (i = 1; i <= nfold; i++) if (index(s, foldfrom[i])) gsub(foldfrom[i], foldto[i], s)
  return s
}
'
