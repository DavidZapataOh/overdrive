#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p apps/web/scripts
printf 'export const steps = () => [];\n' > apps/web/scripts/vercel-build.mjs
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > apps/web/scripts/vercel-build.test.mjs
