#!/usr/bin/env bash
# Helpers shared by the classifier tests. Sourced by tests/risk/test-*.sh.

overdrive() { "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" "$@"; }

# risk REPO ARGS...: classifier output for REPO in $out; the exit code is kept in $rc.
# shellcheck disable=SC2034
risk() {
  local repo=$1
  shift
  rc=0
  out=$(overdrive risk --repo "$repo" "$@" 2>err) || rc=$?
}

# A test next to each source file keeps the computed untested-change item out of
# assertions that are about something else.
source_with_test() {
  write_file "$1" "$2" 'export const x = 1;'
  write_file "$1" "${2%.*}.test.${2##*.}" 'test("x", () => {});'
}

# commit_all REPO MESSAGE: commit everything in the working tree.
commit_all() {
  git -C "$1" add -A
  git -C "$1" commit -q -m "$2"
}

risk_line() {
  printf '%s\n' "$out" | tail -n 1
}

windows_fs() {
  case $OSTYPE in msys* | cygwin*) return 0 ;; esac
  return 1
}
