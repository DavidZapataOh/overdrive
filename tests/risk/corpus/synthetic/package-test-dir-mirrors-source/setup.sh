#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p packages/b/src/util packages/b/test/util
printf '{}\n' > packages/b/package.json
printf 'export const d = 1;\n' > packages/b/src/util/date.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > packages/b/test/util/date.test.ts
