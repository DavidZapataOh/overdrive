#!/usr/bin/env bash
set -eu
printf 'export const a = 2;\n' > src/a.ts
printf 'test("b again", () => {});\n' >> src/b.test.ts
