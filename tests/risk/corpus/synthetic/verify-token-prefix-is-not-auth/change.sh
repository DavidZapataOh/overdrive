#!/usr/bin/env bash
set -eu
printf 'export const check = (t) => verifyTokenShape(t);\n' > src/forms/shape.ts
