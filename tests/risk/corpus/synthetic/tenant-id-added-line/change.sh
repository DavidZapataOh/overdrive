#!/usr/bin/env bash
set -eu
printf 'export const listFor = (db: any, t: string) => db.select("orders").where("tenant_id", t);\n' >> src/orders/query.ts
