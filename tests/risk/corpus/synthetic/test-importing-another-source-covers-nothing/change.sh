#!/usr/bin/env bash
set -eu
mkdir -p test
printf 'export const b = 2;\n' > src/b.ts
printf 'import { a } from "../src/a";\ntest("a", () => {});\n' > test/other.test.ts
