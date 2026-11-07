#!/usr/bin/env bash
set -eu
mkdir -p src/author
printf 'export const name = (a: string) => a;\n' > src/author/profile.ts
printf 'import { test } from "vitest";\ntest("name", () => {});\n' > src/author/profile.test.ts
