#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const run = () => 1;\n' > src/jobs.ts
printf 'import { test } from "vitest";\ntest("run", () => {});\n' > src/jobs.test.ts
