#!/usr/bin/env bash
# Usage: tools/check-skills.sh PLUGIN_DIR
# Checks the shape of every skill: frontmatter, sizes, descriptions and references.

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib/skillmeta.sh
. "$here/lib/skillmeta.sh"

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: check-skills.sh PLUGIN_DIR" >&2
  exit 2
fi
plugin=${1%/}

failed=0
fail() {
  printf '%s: %s\n' "$1" "$2" >&2
  failed=1
}

check_references() {
  local skill=$1 file=$2 dir=$3 ref lines link
  for ref in "$dir"/references/*.md; do
    [ -f "$ref" ] || continue
    lines=$(wc -l < "$ref" | tr -d ' \t')
    if [ "$lines" -gt 100 ] &&
      ! head -n 15 "$ref" | grep -qiE '^#{1,6}[[:space:]]+(table of contents|contents|toc)[[:space:]]*$'; then
      fail "skills/$skill/references/$(basename "$ref")" "more than 100 lines without a table of contents in the first 15 lines"
    fi
  done
  while IFS= read -r link; do
    [ -e "$dir/$link" ] || fail "skills/$skill/SKILL.md" "links to missing $link"
  done < <(grep -oE '(^|[^A-Za-z0-9._/-])references/[A-Za-z0-9._/-]+' "$file" | sed -E 's/^[^r]?references\//references\//; s/[.,;:)]+$//' | sort -u)
}

check_skill() {
  local dir=$1 skill file label name desc visible total close body bytes len
  skill=$(basename "$dir")
  file="$dir/SKILL.md"
  [ -f "$file" ] || return 0
  label="skills/$skill/SKILL.md"

  if [ "$(head -n 1 "$file" | tr -d '\r')" != "---" ]; then
    fail "$label" "frontmatter must start at line 1"
    return
  fi
  close=$(awk 'NR > 1 { sub(/\r$/, ""); if ($0 == "---") { print NR; exit } }' "$file")
  if [ -z "$close" ]; then
    fail "$label" "frontmatter is not closed"
    return
  fi

  total=$(wc -l < "$file" | tr -d ' \t')
  # A last line without a newline still counts as a line.
  [ -n "$(tail -c 1 "$file")" ] && total=$((total + 1))
  body=$((total - close))
  [ "$body" -gt 499 ] && fail "$label" "body has $body lines (limit 499)"
  bytes=$(wc -c < "$file" | tr -d ' \t')
  [ "$bytes" -gt 20000 ] && fail "$label" "file is $bytes bytes, larger than 20000 bytes"

  name=$(fm_get "$file" name) || name=""
  if ! printf '%s\n' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    fail "$label" "name \"$name\" does not match ^[a-z0-9]+(-[a-z0-9]+)*\$"
  elif [ "$name" != "$skill" ]; then
    fail "$label" "name \"$name\" does not match directory \"$skill\""
  fi

  if ! desc=$(fm_get "$file" description) || [ -z "$desc" ]; then
    fail "$label" "description missing"
  else
    len=$(chars_of "$desc")
    [ "$len" -gt 1024 ] && fail "$label" "description longer than 1024 characters ($len)"
    case $desc in
      *'<'* | *'>'*) fail "$label" "description contains < or >" ;;
    esac
    case $desc in
      "I "*) fail "$label" "description must be third person (starts with \"I \")" ;;
      "You "*) fail "$label" "description must be third person (starts with \"You \")" ;;
    esac
    visible=$(fm_get "$file" disable-model-invocation) || visible=""
    if [ "$visible" != "true" ] && [ "$len" -gt 300 ]; then
      fail "$label" "model-visible description longer than 300 characters ($len)"
    fi
  fi

  check_references "$skill" "$file" "$dir"
}

if [ -d "$plugin/skills" ]; then
  for dir in "$plugin"/skills/*/; do
    [ -d "$dir" ] || continue
    check_skill "${dir%/}"
  done
fi

# Smoke cases run on every pull request without a judge: a paid grader there would bill each run.
check_smoke_cases() {
  local evals=$plugin/evals dir rel file kind
  [ -d "$evals" ] || return 0
  while IFS= read -r file; do
    dir=$(dirname "$file")
    rel=${dir#"$evals"/}
    case $rel in _* | results/*) continue ;; esac
    awk '
      FNR == 1 && FILENAME ~ /prompt\.md$/ { fm = ($0 == "---") ; next }
      FILENAME ~ /prompt\.md$/ && fm && $0 == "---" { fm = 0; next }
      FILENAME ~ /prompt\.md$/ && !fm { next }
      /^[[:space:]]*tags:.*-smoke/ || /^[[:space:]]+-[[:space:]]+[A-Za-z0-9-]*-smoke[[:space:]]*$/ { found = 1 }
      END { exit found ? 0 : 1 }
    ' "$file" || continue
    for kind in llm baseline; do
      if grep -qE "^[[:space:]-]*type:[[:space:]]*${kind}[[:space:]]*\$" "$dir/case.yaml" "$dir"/graders/*.md 2>/dev/null; then
        fail "evals/$rel" "smoke case uses a paid grader ($kind)"
      fi
    done
  done < <(find "$evals" \( -name prompt.md -o -name case.yaml \) -type f | LC_ALL=C sort)
}
check_smoke_cases

exit "$failed"
