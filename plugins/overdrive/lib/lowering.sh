#!/usr/bin/env bash
# Reading the decision that lowers a lane: an entry of the decisions log and whether its
# Source is the user's own words. Sourced by the Stop hook and the PreToolUse guard,
# never executed; needs $plugin set to the plugin's root.

if [ -n "${_OD_LOWERING_LOADED:-}" ]; then return 0; fi
_OD_LOWERING_LOADED=1

# trim VALUE: set TRIMMED to VALUE without surrounding whitespace.
trim() {
  TRIMMED=${1#"${1%%[![:space:]]*}"}
  TRIMMED=${TRIMMED%"${TRIMMED##*[![:space:]]}"}
}

# decision ROOT ID: read entry ID of ROOT's decisions log into D_TITLE, D_STATUS and
# D_SOURCE. Fails when the log or the entry cannot be read.
# shellcheck disable=SC2154,SC2034  # plugin and the D_* results belong to the caller
decision() {
  local file=$1/.overdrive/decisions.md out line
  D_TITLE='' D_STATUS='' D_SOURCE='' D_DECISION=''
  [ -f "$file" ] || return 1
  out=$("$BASH" "$plugin/bin/overdrive" decisions show "$2" "$file" 2>/dev/null) || return 1
  while IFS= read -r line; do
    line=${line%$'\r'}
    case $line in
      "## $2 — "*) [ -n "$D_TITLE" ] || D_TITLE=${line#"## $2 — "} ;;
      '- Status:'*) trim "${line#- Status:}"; D_STATUS=$TRIMMED ;;
      '- Source:'*) trim "${line#- Source:}"; D_SOURCE=$TRIMMED ;;
      '- Decision:'*) trim "${line#- Decision:}"; D_DECISION=$TRIMMED ;;
    esac
  done <<<"$out"
  trim "$D_TITLE"
  D_TITLE=$TRIMMED
}

# users_words SOURCE: true when SOURCE quotes someone other than the agent:
# "<quote>" — <who>, <date>, where no whole word of the attribution names an agent.
users_words() {
  local who w
  case $1 in '"'*'" — '?*', '?*) ;; *) return 1 ;; esac
  who=${1##*'" — '}
  shopt -s nocasematch
  for w in ${who//[!A-Za-z0-9]/ }; do
    case $w in
      claude | assistant | agent | overdrive | model | ai) shopt -u nocasematch; return 1 ;;
    esac
  done
  shopt -u nocasematch
  return 0
}

# in_base ROOT ID: true when entry ID is already in the decisions log at BASE (a commit),
# so it predates this change.
in_base() {
  local log
  [ -n "$BASE" ] || return 1
  log=$(git -C "$1" cat-file -p "$BASE:.overdrive/decisions.md" 2>/dev/null) || return 1
  case $'\n'$log in *$'\n'"## $2 "* | *$'\n'"## $2"$'\n'* | *$'\n'"## $2"$'\r'*) return 0 ;; esac
  return 1
}
