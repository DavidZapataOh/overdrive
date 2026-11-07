#!/usr/bin/env bash
set -eu
mkdir -p src/devices
printf 'export const x = 1;\n' > src/devices/Charger.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/devices/Charger.test.ts
