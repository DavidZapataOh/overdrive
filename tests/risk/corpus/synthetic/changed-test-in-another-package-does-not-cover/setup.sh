#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p packages/a/src packages/b/test
printf '{}\n' > packages/a/package.json
printf '{}\n' > packages/b/package.json
printf 'export const f = 1;\n' > packages/a/src/format.ts
