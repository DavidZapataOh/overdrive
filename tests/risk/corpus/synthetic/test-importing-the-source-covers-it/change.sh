#!/usr/bin/env bash
set -eu
mkdir -p test
printf 'export const route = 2;\n' > src/app.ts
printf 'import { route } from "../src/app";\ntest("route", () => {});\n' > test/export.test.ts
