#!/usr/bin/env bash
set -eu
printf 'export const score = (n: number) => n * 2;\n' > src/ranking/score.ts
