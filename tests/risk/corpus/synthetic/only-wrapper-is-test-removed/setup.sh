#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const add = 1;\n' > src/math.ts
printf 'import { describe, it } from "vitest";\ndescribe("math", () => {\nit("a", () => {});\nit("b", () => {});\n});\n' > src/math.test.ts
