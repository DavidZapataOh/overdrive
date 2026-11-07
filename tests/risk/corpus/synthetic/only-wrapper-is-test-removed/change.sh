#!/usr/bin/env bash
set -eu
printf 'import { describe, it } from "vitest";\ndescribe("math", () => {\nit("a", () => {});\nit("b", () => {});\nit.only("c", () => {});\n});\n' > src/math.test.ts
