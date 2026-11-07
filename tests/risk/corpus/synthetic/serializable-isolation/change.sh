#!/usr/bin/env bash
set -eu
printf 'export const begin = "BEGIN ISOLATION LEVEL SERIALIZABLE";\n' > src/ledger/tx.ts
