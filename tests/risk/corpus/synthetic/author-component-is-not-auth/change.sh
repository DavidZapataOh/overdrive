#!/usr/bin/env bash
set -eu
mkdir -p src/components
printf 'export const x = 1;\n' > src/components/Author.tsx
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/components/Author.test.tsx
