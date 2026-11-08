#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project notes
fx_claude_md '# Rules
- Code is in English.
- Run npm test before finishing.'
fx_file README.md '# notes

## Setup

Run npm install, then npm test. You will recieve a summary of the results.'
fx_file src/index.js 'module.exports = { name: "notes" };'
fx_commit "Add the notes package"
