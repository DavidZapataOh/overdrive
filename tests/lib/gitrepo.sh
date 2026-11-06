#!/usr/bin/env bash
# Fixtures for throwaway git repositories.

make_repo() {
  local dir
  dir=$(mktemp -d "${TMPDIR:-/tmp}/od.XXXXXX") || return 1
  git init -q "$dir" || return 1
  git -C "$dir" config user.name "Test"
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config commit.gpgsign false
  git -C "$dir" commit -q --allow-empty -m "init" || return 1
  printf '%s\n' "$dir"
}

write_file() {
  local repo=$1 path=$2
  mkdir -p "$repo/$(dirname "$path")"
  printf '%s\n' "$3" > "$repo/$path"
}

stage_all() {
  git -C "$1" add -A
}

commit_file() {
  write_file "$1" "$2" "$3"
  stage_all "$1"
  git -C "$1" commit -q -m "add $2"
}
