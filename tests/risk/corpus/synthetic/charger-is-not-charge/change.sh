#!/usr/bin/env bash
set -eu
mkdir -p src/charger
printf 'export const status = "idle";\n' > src/charger/status.ts
printf 'import { test } from "vitest";\ntest("status", () => {});\n' > src/charger/status.test.ts
