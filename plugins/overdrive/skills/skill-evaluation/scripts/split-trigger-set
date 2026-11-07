#!/usr/bin/env bash
# Usage: split-trigger-set DIR
# Tags every trigger case (a directory with a prompt.md) below DIR as train or validation.
# The tags line must be a flow list (tags: [a, b]) or absent.

set -u

# Stable 60/40 assignment by checksum of the case name, so adding or removing cases never moves
# another case between the splits. Kept inline because the skill ships this file on its own.
od_split_bucket() {
  local sum
  sum=$(printf '%s' "$1" | cksum | awk '{ print $1 }')
  if [ $((sum % 100)) -lt 60 ]; then
    echo train
  else
    echo validation
  fi
}

if [ "$#" -ne 1 ]; then
  echo "usage: $(basename "$0") DIR" >&2
  exit 64
fi
[ -d "$1" ] || { echo "split-trigger-set: not a directory: $1" >&2; exit 1; }

tmp=$(mktemp "${TMPDIR:-/tmp}/od-split.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT

status=0
while IFS= read -r file; do
  name=$(basename "$(dirname "$file")")
  bucket=$(od_split_bucket "$name")
  if ! awk -v bucket="$bucket" '
    function tags_line(v,   inner, n, parts, i, t, u, out) {
      inner = substr(v, 2, length(v) - 2)
      n = split(inner, parts, ",")
      out = ""
      for (i = 1; i <= n; i++) {
        t = parts[i]
        gsub(/^[ \t]+|[ \t]+$/, "", t)
        u = t
        gsub(/["\047]/, "", u)
        if (u == "" || u == "train" || u == "validation") continue
        out = out (out == "" ? "" : ", ") t
      }
      return "tags: [" out (out == "" ? "" : ", ") bucket "]"
    }
    BEGIN { state = 0; seen = 0 }
    {
      line = $0
      cr = ""
      if (line ~ /\r$/) { sub(/\r$/, "", line); cr = "\r" }
      if (state == 0) {
        if (NR == 1 && line == "---") { state = 1; print line cr; next }
        print "---" cr; print "tags: [" bucket "]" cr; print "---" cr
        state = 2
        print line cr
        next
      }
      if (state == 1) {
        if (line == "---") {
          if (!seen) print "tags: [" bucket "]" cr
          state = 2
          print line cr
          next
        }
        if (line ~ /^tags:/) {
          v = line
          sub(/^tags:[ \t]*/, "", v)
          sub(/[ \t]+$/, "", v)
          if (v !~ /^\[.*\]$/) { bad = 1; exit 3 }
          seen = 1
          print tags_line(v) cr
          next
        }
      }
      print line cr
    }
    END { if (state == 1 && !bad) exit 4 }
  ' "$file" > "$tmp"; then
    echo "split-trigger-set: $file: tags must be a flow list like [a, b], and the front matter must be closed" >&2
    status=1
    continue
  fi
  if ! cmp -s "$file" "$tmp"; then
    cat "$tmp" > "$file"
  fi
done < <(find "$1" -type f -name prompt.md | LC_ALL=C sort)

exit "$status"
