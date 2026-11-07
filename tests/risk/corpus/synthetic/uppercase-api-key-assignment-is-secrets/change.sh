#!/usr/bin/env bash
set -eu
value=Zq; for _ in 1 2 3 4 5 6 7; do value="${value}x9"; done
printf 'export const API_KEY = "%s";\n' "$value" > src/client.ts
