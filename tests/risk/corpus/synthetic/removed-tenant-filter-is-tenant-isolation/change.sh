#!/usr/bin/env bash
set -eu
printf 'export const find = (db) => db.all();\n' > src/repo/orders.ts
