#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Usage: tests/run.sh [FILTER]
# FILTER is an extended regular expression matched against test file paths.

here=$(cd "$(dirname "$0")" && pwd)
tests_dir=${TESTS_DIR:-$here}
filter=${1:-.}
RUNNER="$here/run.sh"
export RUNNER

work=$(mktemp -d "${TMPDIR:-/tmp}/od.XXXXXX") || exit 1
# Tests that keep locked eval sandboxes must not make the cleanup fail.
trap 'chmod -R u+rwx "$work" 2>/dev/null; rm -rf "$work"' EXIT
# Fixtures made with mktemp land inside the work dir and are removed on exit.
TMPDIR=$work
export TMPDIR

n=0
failed=0

find "$tests_dir" -type f -name 'test-*.sh' | LC_ALL=C sort | grep -E -- "$filter" > "$work/files"

while IFS= read -r file; do
  names=$(
    . "$file"
    declare -F | awk '$3 ~ /^test_/ { print $3 }' | LC_ALL=C sort
  )
  for name in $names; do
    n=$((n + 1))
    sandbox="$work/t$n"
    mkdir "$sandbox"
    # Not in an if condition: bash disables set -e inside a subshell used as one,
    # and so does the left side of ||.
    (
      set -e
      cd "$sandbox"
      . "$here/lib/assert.sh"
      . "$here/lib/gitrepo.sh"
      . "$file"
      "$name"
    ) >"$work/out$n" 2>&1
    rc=$?
    if [ "$rc" -eq 0 ]; then
      printf 'ok %d %s\n' "$n" "$name"
    else
      failed=$((failed + 1))
      printf 'not ok %d %s\n' "$n" "$name"
      sed 's/^/    /' "$work/out$n"
    fi
  done
done < "$work/files"

printf '%d tests, %d failed\n' "$n" "$failed"
[ "$n" -gt 0 ] && [ "$failed" -eq 0 ]
