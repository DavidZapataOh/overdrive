#!/usr/bin/env bash
set -eu
value=super; for _ in 1 2 3; do value="${value}secret"; done
printf 'export const users = { admin: { password: "{noop}%s" } };\n' "$value" > src/conf/users.ts
