#!/usr/bin/env bash
set -eu
printf 'export const placeAll = async (db: any) => await db.transaction(async (tx: any) => tx);\n' >> src/orders/place.ts
