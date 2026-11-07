#!/usr/bin/env bash
set -eu
mkdir -p src/refund-policy
printf 'export const days = 30;\n' > src/refund-policy/days.ts
printf 'import { test } from "vitest";\ntest("days", () => {});\n' > src/refund-policy/days.test.ts
