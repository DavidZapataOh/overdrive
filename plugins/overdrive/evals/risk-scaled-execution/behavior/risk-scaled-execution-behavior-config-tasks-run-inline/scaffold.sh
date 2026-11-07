#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project webapp
fx_file docs/plan.md '# Config plan

## Global Constraints

Config files only.

### Task 1: Editor config

**Files:**
- Create: `.editorconfig`

Add a root `.editorconfig` with `root = true`, UTF-8, LF line endings, two-space indent.

### Task 2: Node version

**Files:**
- Create: `.nvmrc`

Pin Node to major version 22 (file content `22`).

### Task 3: Formatter settings

**Files:**
- Create: `.prettierrc`

JSON with `"singleQuote": true` and `"semi": true`.

### Task 4: Attributes

**Files:**
- Create: `.gitattributes`

One line: `* text=auto eol=lf`.'
fx_commit "Add config plan"
