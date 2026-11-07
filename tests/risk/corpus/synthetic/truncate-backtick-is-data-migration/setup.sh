#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/db
printf 'export const reset = 1;\n' > src/db/reset.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/db/reset.test.ts
