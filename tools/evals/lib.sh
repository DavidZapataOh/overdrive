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
