#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project recipes
fx_file src/shelf.js 'exports.add = (entry) => entry;'
fx_file docs/plan.md '### Task 2: Recipe parser

**Files:**
- Create: `src/recipe.js`

Create `parse_recipe(raw)` in `src/recipe.js`, matching the snake_case style of `src/shelf.js` helpers.

### Task 3: Shelve parsed recipes

**Files:**
- Modify: `src/shelf.js`

Call `parseRecipe(raw)` and add each line with `add`.

### Task 4: Serving counts

**Files:**
- Create: `src/servings.js`

`servings(lines)` sums the `portions` of every line and returns the number.

### Task 5: Servings report

**Files:**
- Create: `src/report.js`

`report(lines)` returns the string `Servings: ` followed by `servings(lines)`.'
fx_commit "Initial commit"
