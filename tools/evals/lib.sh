#!/usr/bin/env bash
# Shared by the eval tools; source it, do not run it.

# The native Windows jq writes CRLF unless told otherwise (-b); elsewhere the flag does nothing.
jq() { command jq -b "$@"; }

# od_split_bucket NAME: stable 60/40 assignment by checksum of the case name, so adding or
# removing cases never moves another case between the splits. split-trigger-set.sh carries its
# own copy (the skill ships it alone); a test keeps the two in agreement.
od_split_bucket() {
  local sum
  sum=$(printf '%s' "$1" | cksum | awk '{ print $1 }')
  if [ $((sum % 100)) -lt 60 ]; then
    echo train
  else
    echo validation
  fi
}

# od_model_id KEY: the pinned model ID for main or sonnet.
od_model_id() {
  case $1 in
    main) echo "$OD_EVAL_MODEL_MAIN" ;;
    sonnet) echo "$OD_EVAL_MODEL_SONNET" ;;
    *) return 1 ;;
  esac
}

# od_prepare_env: makes the environment safe for `claude plugin eval`. Call it before running claude.
od_prepare_env() {
  local dir entry kept='' rest
  # The eval's OS sandbox mounts everything under /tmp read-only on Linux, so a temp tree there
  # leaves Bash in the runs unable to write the workspace or TMPDIR.
  if [ -n "${OVERDRIVE_EVAL_TMPDIR-}" ]; then
    dir=$OVERDRIVE_EVAL_TMPDIR
  elif [ "$(uname -s)" = Linux ]; then
    case ${TMPDIR:-/tmp} in
      /tmp | /tmp/*) dir=${XDG_CACHE_HOME:-$HOME/.cache}/overdrive-evals/tmp ;;
    esac
  fi
  if [ -n "${dir-}" ]; then
    mkdir -p "$dir" || return 1
    TMPDIR=$dir
    export TMPDIR
  fi

  # The CLI refuses to start when PATH holds a directory it cannot read (Windows paths on WSL).
  rest=$PATH
  while :; do
    entry=${rest%%:*}
    if [ -n "$entry" ] && [ -d "$entry" ] && [ -r "$entry" ] && [ -x "$entry" ]; then
      kept=${kept:+$kept:}$entry
    fi
    case $rest in *:*) rest=${rest#*:} ;; *) break ;; esac
  done
  # The plugin's bin/ is not on the Bash tool's PATH in eval runs, but the shell's PATH is, so a
  # stand-in gh for the release skills goes in front of any real one.
  PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin${kept:+:$kept}
  export PATH
}
