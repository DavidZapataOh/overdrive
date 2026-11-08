#!/usr/bin/env bash
# Usage: tools/check-budget.sh PLUGIN_DIR
# Measures what the plugin puts in every session's context: the SessionStart
# injection and the model-visible skill and agent descriptions, as ceil(chars / 3.5).
# Characters are counted, not bytes, so accented text is not over-counted.

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib/skillmeta.sh
. "$here/lib/skillmeta.sh"

injection_limit=1000
descriptions_limit=1200

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: check-budget.sh PLUGIN_DIR" >&2
  exit 2
fi
plugin=$(cd "$1" && pwd)

# The hook is run the way Claude Code runs it: event JSON on stdin, plugin root in the environment.
injection_chars=0
hook="$plugin/hooks/session-start"
if [ -f "$hook" ]; then
  raw=$(printf '{"hook_event_name":"SessionStart","source":"startup"}' |
    CLAUDE_PLUGIN_ROOT=$plugin bash "$hook") || {
    echo "hooks/session-start failed" >&2
    exit 1
  }
  # Plain stdout is also injected as context; JSON output carries it in additionalContext.
  if printf '%s' "$raw" | jq -e 'type == "object"' >/dev/null 2>&1; then
    text=$(printf '%s' "$raw" | jq -r '.hookSpecificOutput.additionalContext // ""')
  else
    text=$raw
  fi
  # Measured with the root a marketplace install has, not this checkout's path.
  install=${HOME:-/home/user}/.claude/plugins/cache/overdrive/overdrive/0.1.0
  text=${text//"$plugin"/"$install"}
  injection_chars=$(chars_of "$text")
else
  echo "note: hooks/session-start not found, injection counted as 0"
fi

desc_chars=0
add_chars() {
  desc_chars=$((desc_chars + $(chars_of "$1")))
}

for file in "$plugin"/skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  hidden=$(fm_get "$file" disable-model-invocation) || hidden=""
  [ "$hidden" = "true" ] && continue
  for key in name description when_to_use; do
    value=$(fm_get "$file" "$key") || continue
    add_chars "$value"
  done
done
for file in "$plugin"/agents/*.md; do
  [ -f "$file" ] || continue
  for key in name description; do
    value=$(fm_get "$file" "$key") || continue
    add_chars "$value"
  done
done

injection=$(tokens_for "$injection_chars")
descriptions=$(tokens_for "$desc_chars")
printf 'injection_tokens=%s descriptions_tokens=%s\n' "$injection" "$descriptions"

# Informational cross-check against the CLI's own projection; never fails the check.
if command -v claude >/dev/null 2>&1; then
  details=$(claude plugin details overdrive 2>&1 | grep -i 'every turn' || true)
  [ -n "$details" ] && printf 'claude plugin details: %s\n' "$details"
fi

status=0
if [ "$injection" -gt "$injection_limit" ]; then
  echo "injection over budget: $injection > $injection_limit tokens" >&2
  status=1
fi
if [ "$descriptions" -gt "$descriptions_limit" ]; then
  echo "descriptions over budget: $descriptions > $descriptions_limit tokens" >&2
  status=1
fi
exit "$status"
