#!/usr/bin/env bash
set -eu
salt=abcdefghij
# shellcheck disable=SC2016
printf 'export const ADMIN_PASSWORD = "$2b$10$%s%s";\n' "$salt" "$salt" > src/conf/users.ts
