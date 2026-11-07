#!/usr/bin/env bash
set -eu
mkdir -p src/maintenance
printf 'export const window = "sunday";\n' > src/maintenance/window.ts
printf 'import { test } from "vitest";\ntest("window", () => {});\n' > src/maintenance/window.test.ts
