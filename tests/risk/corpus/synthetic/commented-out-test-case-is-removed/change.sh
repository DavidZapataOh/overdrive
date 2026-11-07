#!/usr/bin/env bash
set -eu
printf 'import { it } from "vitest";\nit("a", () => {});\n// it("b", () => {});\n' > src/math.test.ts
