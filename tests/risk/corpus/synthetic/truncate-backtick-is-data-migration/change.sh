#!/usr/bin/env bash
set -eu
# shellcheck disable=SC2016
printf 'export const reset = "truncate `events`";\n' > src/db/reset.ts
