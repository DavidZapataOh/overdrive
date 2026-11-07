#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/ranking
printf 'export const score = (n: number) => n;\n' > src/ranking/score.ts
printf 'import { test } from "vitest";\ntest("score", () => {});\n' > src/ranking/score.test.ts
