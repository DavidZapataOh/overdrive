#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p apps/web/src/lib/pricing
printf 'export const tiers = [1, 2];\n' > apps/web/src/lib/pricing/table.ts
printf 'import { test } from "vitest";\ntest("tiers", () => {});\n' > apps/web/src/lib/pricing/table.test.ts
