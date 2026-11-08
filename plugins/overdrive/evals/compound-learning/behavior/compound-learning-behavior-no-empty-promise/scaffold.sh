#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project tools
fx_claude_md '# Rules
- Code is in English.
- Run the tests before finishing.'
fx_file pnpm-lock.yaml "lockfileVersion: '9.0'"
fx_file src/index.js 'module.exports = { name: "tools" };'
fx_file package-lock.json '{
  "name": "tools",
  "lockfileVersion": 3
}'
fx_commit "Add the tools package"
