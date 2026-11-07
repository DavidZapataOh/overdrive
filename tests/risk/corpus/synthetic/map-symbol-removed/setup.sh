#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const computeScore = (x: number) => x * 2;\nexport const label = "rank";\n' > src/rank.ts
printf 'import { test } from "vitest";\ntest("rank", () => {});\n' > src/rank.test.ts
