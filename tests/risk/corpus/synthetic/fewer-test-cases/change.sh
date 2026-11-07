#!/usr/bin/env bash
set -eu
printf 'import { it } from "vitest";\nit("a", () => {});\nit("b and c", () => {});\n' > src/math.test.ts
