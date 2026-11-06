#!/usr/bin/env bash
# Path glob matching translated to an anchored ERE. Sourced, never executed.
# Supported: ** (any depth, including none when written as **/), * (no slash),
# ? (one non-slash character). Everything else is literal, so [ ] { } stay literal.

if [ -n "${_OD_GLOB_LOADED:-}" ]; then return 0; fi
_OD_GLOB_LOADED=1

_GLOB_RE=
_GLOB_LAST_PATTERN=

# _glob_compile PATTERN: set _GLOB_RE; the last pattern is cached because callers
# match many paths against the same pattern.
_glob_compile() {
  if [ "${_GLOB_LAST_PATTERN-}" = "$1" ] && [ -n "$_GLOB_RE" ]; then return 0; fi
  local p=$1 re='^' c
  while [ -n "$p" ]; do
    c=${p:0:1}
    case $c in
      '*')
        if [ "${p:1:1}" = '*' ]; then
          if [ "${p:2:1}" = '/' ]; then
            re=$re'(.*/)?'
            p=${p:3}
          else
            re=$re'.*'
            p=${p:2}
          fi
        else
          re=$re'[^/]*'
          p=${p:1}
        fi
        continue
        ;;
      '?') re=$re'[^/]' ;;
      '.' | '+' | '(' | ')' | '[' | ']' | '{' | '}' | '^' | '$' | '|' | \\) re=$re\\$c ;;
      *) re=$re$c ;;
    esac
    p=${p:1}
  done
  _GLOB_RE=$re'$'
  _GLOB_LAST_PATTERN=$1
}

glob_to_regex() {
  _glob_compile "$1"
  printf '%s\n' "$_GLOB_RE"
}

# glob_match PATH PATTERN: exit 0 when PATH matches.
glob_match() {
  _glob_compile "$2"
  [[ $1 =~ $_GLOB_RE ]]
}
