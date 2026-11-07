#!/usr/bin/env bash
set -eu
printf 'export const user = (id: string) => ({ id });\n' >> src/api/users.ts
