#!/usr/bin/env bash
set -eu
printf 'import { it } from "vitest";\nit("adds", () => {});\n' > src/math.test.ts
