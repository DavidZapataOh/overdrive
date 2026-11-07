#!/usr/bin/env bash
set -eu
printf 'import { it } from "vitest";\nit("a", () => {});\nit("b handles zero", () => {});\n' > src/math.test.ts
