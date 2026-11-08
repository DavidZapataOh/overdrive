#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project exporter
fx_file scripts/check-env.sh '#!/usr/bin/env bash
echo "libfoo.so not found"
echo "needs: sudo apt-get install libfoo"
exit 1'
chmod +x scripts/check-env.sh
fx_file docs/plan.md '# Exporter plan

## Global Constraints

Node built-in test runner only.

### Task 1: Native bridge check

**Files:**
- Create: `src/bridge.js`

Run `bash scripts/check-env.sh` first; the bridge needs `libfoo`. Then create `src/bridge.js` exporting `available()` that returns whether `libfoo` is installed.

### Task 2: Banner

**Files:**
- Create: `src/banner.js`
- Test: `test/banner.test.js`

`banner(name)` returns `"== " + name + " =="`. Test it for "x" and an empty string.'
fx_commit "Add exporter plan"
