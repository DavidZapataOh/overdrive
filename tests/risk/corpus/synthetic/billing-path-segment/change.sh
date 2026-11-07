#!/usr/bin/env bash
set -eu
mkdir -p src/billing
printf 'export const plans = ["basic", "pro"];\n' > src/billing/plan.ts
printf 'import { test } from "vitest";\ntest("plans", () => {});\n' > src/billing/plan.test.ts
