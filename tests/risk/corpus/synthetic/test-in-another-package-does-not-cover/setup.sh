#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p packages/a/src packages/b/src
printf '{}\n' > packages/a/package.json
printf '{}\n' > packages/b/package.json
printf 'export const a = 1;\n' > packages/a/src/index.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > packages/a/src/index.test.ts
printf 'export const b = 1;\n' > packages/b/src/index.ts
