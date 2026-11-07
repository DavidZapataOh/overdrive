#!/usr/bin/env bash
set -eu
printf 'export const tiers = [1, 2, 3];\n' > apps/web/src/lib/pricing/table.ts
