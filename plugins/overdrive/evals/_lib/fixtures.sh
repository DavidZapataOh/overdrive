#!/usr/bin/env bash
# Sourced by eval scaffold scripts. Builds fixture projects in the current directory.
# The eval workspace never loads CLAUDE.md or .claude/, so fixtures that need project
# rules write them as ordinary files for the skill under test to read.

fx_git_repo() {
  git init -q -b main . || return 1
  git config user.name "Eval Fixture"
  git config user.email "fixture@example.invalid"
  git config commit.gpgsign false
  git config core.autocrlf false
}

# No installs: tests run with the Node built-in runner.
fx_node_project() {
  [ -n "${1-}" ] || { echo "fx_node_project: project name required" >&2; return 1; }
  fx_file package.json "$(printf '{\n  "name": "%s",\n  "version": "1.0.0",\n  "private": true,\n  "scripts": {\n    "test": "node --test"\n  }\n}' "$1")"
}

# A Claude Code plugin at the workspace root: manifest plus an empty skills/.
fx_plugin() {
  [ -n "${1-}" ] || { echo "fx_plugin: plugin name required" >&2; return 1; }
  mkdir -p skills || return 1
  fx_file .claude-plugin/plugin.json "$(printf '{\n  "name": "%s",\n  "version": "1.0.0",\n  "description": "%s"\n}' "$1" "${2:-$1}")"
}

fx_file() {
  local dir
  [ -n "${1-}" ] || { echo "fx_file: path required" >&2; return 1; }
  dir=$(dirname "$1")
  mkdir -p "$dir" || return 1
  printf '%s\n' "${2-}" > "$1"
}

fx_commit() {
  [ -n "${1-}" ] || { echo "fx_commit: message required" >&2; return 1; }
  git add -A || return 1
  git commit -q --allow-empty -m "$1"
}

# One rule per argument, in the risk map grammar.
fx_risk_map() {
  mkdir -p .overdrive || return 1
  : > .overdrive/risk-map.conf
  local rule
  for rule in "$@"; do
    printf '%s\n' "$rule" >> .overdrive/risk-map.conf
  done
}

# One complete "## D-NNNN" entry per argument.
fx_decisions() {
  mkdir -p .overdrive || return 1
  printf '# Decisions\nRules live in: CLAUDE.md files and the project memory index. This file holds rulings only.\n' > .overdrive/decisions.md
  local entry
  for entry in "$@"; do
    printf '\n%s\n' "$entry" >> .overdrive/decisions.md
  done
}

fx_claude_md() {
  [ -n "${1-}" ] || { echo "fx_claude_md: text required" >&2; return 1; }
  fx_file CLAUDE.md "$1"
}
