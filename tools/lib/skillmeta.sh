#!/usr/bin/env bash
# Shared helpers for the static guards. Sourced, not executed.

# Prints the value of a top-level frontmatter key; exit 1 when the key is absent.
# Block scalars (> and |) are folded onto one line, which is how descriptions are measured.
fm_get() {
  awk -v key="$2" '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; infm = 1; next }
    infm && $0 == "---" { exit }
    infm {
      if ($0 ~ /^[A-Za-z0-9_-]+:/) {
        if (found) exit
        k = $0; sub(/:.*/, "", k)
        if (k == key) {
          found = 1
          out = $0; sub(/^[^:]*:[ \t]*/, "", out); sub(/[ \t]+$/, "", out)
          if (out ~ /^[>|][+-]?$/) out = ""
        }
      } else if (found && $0 ~ /^[ \t]+[^ \t]/) {
        v = $0; sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        out = (out == "" ? v : out " " v)
      }
    }
    END {
      if (!found) exit 1
      if (out ~ /^".*"$/ || out ~ /^'"'"'.*'"'"'$/) out = substr(out, 2, length(out) - 2)
      print out
    }
  ' "$1"
}

# Characters on stdin, not bytes: counts every byte except UTF-8 continuation
# bytes, which gives the same answer under any locale and any awk/wc.
char_count() {
  LC_ALL=C tr -d '\200-\277' | LC_ALL=C wc -c | tr -d ' \t'
}

chars_of() {
  printf '%s' "$1" | char_count
}

# ceil(chars / 3.5) in integer arithmetic: ceil(2c / 7).
tokens_for() {
  awk -v c="$1" 'BEGIN { print int((2 * c + 6) / 7) }'
}
