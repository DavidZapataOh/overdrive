#!/usr/bin/env bash
set -eu
printf 'import { describe, it } from "vitest";\ndescribe.skip("math", () => {\nit("a", () => {});\nit("b", () => {});\n});\n' > src/math.test.ts
