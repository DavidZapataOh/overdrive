#!/usr/bin/env bash
set -eu
# shellcheck disable=SC2016
printf 'export const users = { secret: "$%s" };\n' "ecretP4ssw0rd99xx" > src/conf/users.ts
