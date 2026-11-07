#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const counter = new Int32Array(new SharedArrayBuffer(4));\n' > src/counter.js
printf 'import { test } from "vitest";\ntest("counter", () => {});\n' > src/counter.test.js
