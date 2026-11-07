#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'import { it } from "vitest";\nit("a", () => {});\nit("b", () => {});\nit("c", () => {});\n' > src/math.test.ts
