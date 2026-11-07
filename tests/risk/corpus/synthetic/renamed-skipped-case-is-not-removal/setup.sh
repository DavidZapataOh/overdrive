#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const add = 1;\n' > src/math.ts
printf 'import { it } from "vitest";\nit("a", () => {});\nit.skip("b", () => {});\n' > src/math.test.ts
