#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/forms
printf 'export const check = (t) => t;\n' > src/forms/shape.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/forms/shape.test.ts
