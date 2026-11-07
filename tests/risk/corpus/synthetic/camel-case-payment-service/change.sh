#!/usr/bin/env bash
set -eu
mkdir -p src/services
printf 'export const x = 1;\n' > src/services/PaymentService.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/services/PaymentService.test.ts
