#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project notes
fx_file src/text.js 'exports.normalizeTitle = (s) => s.trim();'
fx_file docs/plan.md '# Titles plan

## Global Constraints

Node built-in test runner only.

### Task 1: Slug helper

**Files:**
- Create: `src/slug.js`
- Test: `test/slug.test.js`

Create `makeSlug(title)` in `src/slug.js`: lowercase, spaces and underscores to hyphens, strip other punctuation, using `normalizeTitle` from `src/text.js` first. Export it.

### Task 2: Use the slug builder

**Files:**
- Modify: `src/text.js`
- Test: `test/text.test.js`

Add `slugFor(title)` to `src/text.js` that returns `make_slug(title)` from the helper built in Task 1.'
fx_commit "Add titles plan"
