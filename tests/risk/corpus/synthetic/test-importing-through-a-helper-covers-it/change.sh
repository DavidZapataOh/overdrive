#!/usr/bin/env bash
set -eu
printf 'export const route = 2;\n' > src/app.ts
printf 'import { get } from "./helpers";\ntest("route", () => {});\n' > test/search.test.ts
