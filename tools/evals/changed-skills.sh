#!/usr/bin/env bash
# Usage: changed-skills.sh [--root DIR] [BASE HEAD]
# Prints, one per line, the skills with eval cases that a change affects. Without a range it prints
# every skill that has cases. A change to anything shared (hooks, agents, libraries, fixtures, the
# eval tools) affects all of them.

set -u
export LC_ALL=C

root=$(cd "$(dirname "$0")/../.." && pwd)
if [ "${1-}" = --root ]; then
  root=${2-}
  shift 2 || { echo "usage: changed-skills.sh [--root DIR] [BASE HEAD]" >&2; exit 64; }
fi
if [ "$#" -ne 0 ] && [ "$#" -ne 2 ]; then
  echo "usage: changed-skills.sh [--root DIR] [BASE HEAD]" >&2
  exit 64
fi

evals=plugins/overdrive/evals

# Skills are the directories under evals/ that hold at least one case (a prompt.md or case.yaml).
with_cases() {
  local dir name
  for dir in "$root/$evals"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    # The end-to-end suite is long and costly, so it runs only when asked for by name.
    case $name in _* | results | e2e) continue ;; esac
    if [ -n "$(find "$dir" \( -name prompt.md -o -name case.yaml \) -print -quit)" ]; then
      printf '%s\n' "$name"
    fi
  done | sort
}

if [ "$#" -eq 0 ]; then
  with_cases
  exit 0
fi

paths=$(git -C "$root" diff --name-only "$1...$2" -- 2>/dev/null) || {
  echo "changed-skills: cannot diff $1...$2" >&2
  exit 1
}

all=0
named=''
while IFS= read -r path; do
  [ -n "$path" ] || continue
  case $path in
    plugins/overdrive/skills/* | "$evals"/*)
      rest=${path#plugins/overdrive/}
      rest=${rest#skills/}
      rest=${rest#evals/}
      name=${rest%%/*}
      case $name in
        _* | results) [ "$name" = results ] || all=1 ;;
        e2e) ;;
        *) named="$named$name"$'\n' ;;
      esac
      ;;
    plugins/overdrive/* | tools/evals/* | .github/workflows/evals.yml) all=1 ;;
  esac
done <<EOT
$paths
EOT

if [ "$all" -eq 1 ]; then
  with_cases
else
  with_cases | while IFS= read -r skill; do
    case $'\n'$named in *$'\n'"$skill"$'\n'*) printf '%s\n' "$skill" ;; esac
  done
fi
