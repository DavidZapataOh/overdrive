#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const add = (a: number, b: number) => a + b;\n' > src/math.ts
printf 'import { it } from "vitest";\nit("adds", () => {});\n' > src/math.test.ts
