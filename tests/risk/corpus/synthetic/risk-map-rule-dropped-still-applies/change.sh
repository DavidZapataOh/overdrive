#!/usr/bin/env bash
set -eu
printf 'pathtoken unused unused\n' > .overdrive/risk-map.conf
mkdir -p src/ranking
printf 'export const score = 1;\n' > src/ranking/score.ts
printf 'import { test } from "vitest";\ntest("score", () => {});\n' > src/ranking/score.test.ts
