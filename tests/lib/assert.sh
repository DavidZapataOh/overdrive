#!/usr/bin/env bash
# Assertions print a message to stderr and return 1; tests run with set -e.

assert_eq() {
  if [ "$1" != "$2" ]; then
    printf 'assert_eq failed%s\n  expected: %s\n  actual:   %s\n' "${3:+ ($3)}" "$1" "$2" >&2
    return 1
  fi
}

# Whole-line match so that a prefix of a line never passes.
assert_line() {
  if ! printf '%s\n' "$1" | grep -qxF -- "$2"; then
    printf 'assert_line failed: no line equal to: %s\n  in: %s\n' "$2" "$1" >&2
    return 1
  fi
}

assert_no_line() {
  if printf '%s\n' "$1" | grep -qE -- "$2"; then
    printf 'assert_no_line failed: a line matches: %s\n  in: %s\n' "$2" "$1" >&2
    return 1
  fi
}

assert_exit() {
  local want=$1 got=0
  shift
  "$@" >/dev/null 2>&1 || got=$?
  if [ "$got" != "$want" ]; then
    printf 'assert_exit failed: expected %s, got %s: %s\n' "$want" "$got" "$*" >&2
    return 1
  fi
}

assert_file_contains() {
  if ! grep -qE -- "$2" "$1"; then
    printf 'assert_file_contains failed: %s not found in %s\n' "$2" "$1" >&2
    return 1
  fi
}
