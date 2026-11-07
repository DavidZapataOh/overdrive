#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'import { it } from "vitest";\nit("a", () => {});\nit("b", () => {});\n' > src/math.test.ts
