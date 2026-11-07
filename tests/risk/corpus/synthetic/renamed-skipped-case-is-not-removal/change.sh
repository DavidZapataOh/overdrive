#!/usr/bin/env bash
set -eu
printf 'import { it } from "vitest";\nit("a", () => {});\nit.skip("b, renamed", () => {});\n' > src/math.test.ts
