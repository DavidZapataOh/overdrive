#!/usr/bin/env bash
# Usage: tools/check-forbidden-terms.sh [--staged] [--range A..B] [--message-file FILE] [--pr-event FILE]
#
# Terms come from $OVERDRIVE_FORBIDDEN_TERMS (one per line) and/or the file named by
# $OVERDRIVE_FORBIDDEN_TERMS_FILE. Matching is case-insensitive and literal.
# Hits are reported by location only, never by quoting the matched text.
# Exit: 0 clean, 1 hits, 2 misconfiguration (including no terms when CI=true).

set -u

staged=0
range=""
message_file=""
pr_event=""
while [ "$#" -gt 0 ]; do
  case $1 in
    --staged) staged=1 ;;
    --range | --message-file | --pr-event)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        echo "check-forbidden-terms: $1 needs a value" >&2
        exit 2
      fi
      case $1 in
        --range) range=$2 ;;
        --message-file) message_file=$2 ;;
        --pr-event) pr_event=$2 ;;
      esac
      shift
      ;;
    *)
      echo "check-forbidden-terms: unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

work=$(mktemp -d "${TMPDIR:-/tmp}/terms.XXXXXX") || exit 2
trap 'rm -rf "$work"' EXIT
patterns="$work/patterns"

{
  [ -n "${OVERDRIVE_FORBIDDEN_TERMS:-}" ] && printf '%s\n' "$OVERDRIVE_FORBIDDEN_TERMS"
  [ -n "${OVERDRIVE_FORBIDDEN_TERMS_FILE:-}" ] && [ -f "$OVERDRIVE_FORBIDDEN_TERMS_FILE" ] &&
    cat "$OVERDRIVE_FORBIDDEN_TERMS_FILE"
} 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' > "$patterns"

if [ ! -s "$patterns" ]; then
  if [ "${CI:-}" = "true" ]; then
    echo "check-forbidden-terms: no forbidden terms configured in CI (missing secret?)" >&2
    exit 2
  fi
  echo "check-forbidden-terms: no forbidden terms configured, skipping"
  exit 0
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "check-forbidden-terms: not inside a git repository" >&2
  exit 2
fi
cd "$(git rev-parse --show-toplevel)" || exit 2

hits=0
report() {
  printf '%s\n' "$1"
  hits=1
}

# Reads a text stream on stdin; true when it contains a term.
has_term() { grep -qiF -f "$patterns"; }

if [ "$staged" -eq 1 ]; then
  grep_args="--cached"
  list=(git diff --cached --name-only --diff-filter=AMR -z)
else
  grep_args=""
  list=(git ls-files -z)
fi

# A failing git must never read as "no hits".
"${list[@]}" > "$work/paths" 2>/dev/null || {
  echo "check-forbidden-terms: ${list[0]} ${list[1]} failed" >&2
  exit 2
}
paths=$(tr '\0' '\n' < "$work/paths")

# -I skips binary files; -z keeps unusual file names intact. Exit 1 only means no match.
# shellcheck disable=SC2086
git grep -I -i -F -l -z -f "$patterns" $grep_args -- > "$work/content" 2>/dev/null
rc=$?
if [ "$rc" -gt 1 ]; then
  echo "check-forbidden-terms: git grep failed (exit $rc)" >&2
  exit 2
fi
while IFS= read -r -d '' file; do
  report "content: $file"
done < "$work/content"

while IFS= read -r path; do
  [ -n "$path" ] || continue
  printf '%s\n' "$path" | has_term && report "path: $path"
done <<< "$paths"

# Branch names: the checked-out branch, and the PR head ref that CI exposes on detached checkouts.
for ref in "$(git symbolic-ref --short -q HEAD || true)" "${GITHUB_HEAD_REF:-}" "${GITHUB_REF_NAME:-}"; do
  [ -n "$ref" ] || continue
  printf '%s\n' "$ref" | has_term && report "branch: $ref"
done

if [ -n "$range" ]; then
  if ! shas=$(git rev-list "$range" 2>/dev/null); then
    echo "check-forbidden-terms: cannot resolve range $range (shallow clone?)" >&2
    exit 2
  fi
  for sha in $shas; do
    git log -1 --format=%B "$sha" | has_term && report "commit message: $sha"
  done
fi

if [ -n "$message_file" ]; then
  [ -r "$message_file" ] || {
    echo "check-forbidden-terms: cannot read $message_file" >&2
    exit 2
  }
  has_term < "$message_file" && report "commit message file"
fi

if [ -n "$pr_event" ]; then
  command -v jq >/dev/null 2>&1 || {
    echo "check-forbidden-terms: jq is required for --pr-event" >&2
    exit 2
  }
  jq -e . "$pr_event" >/dev/null 2>&1 || {
    echo "check-forbidden-terms: cannot parse $pr_event" >&2
    exit 2
  }
  jq -r '.pull_request.title // ""' "$pr_event" | has_term && report "pull request title"
  jq -r '.pull_request.body // ""' "$pr_event" | has_term && report "pull request body"
  jq -r '.pull_request.head.ref // ""' "$pr_event" | has_term && report "pull request head ref"
fi

if [ "$hits" -ne 0 ]; then
  echo "check-forbidden-terms: forbidden terms found" >&2
  exit 1
fi
exit 0
