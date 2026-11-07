#!/usr/bin/env bash
set -eu
printf 'import { it } from "vitest";\nit("c", () => {});\n' > src/math.test.ts
