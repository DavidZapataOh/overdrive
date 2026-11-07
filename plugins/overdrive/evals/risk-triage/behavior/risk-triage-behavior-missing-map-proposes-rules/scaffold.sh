#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal Markdown
# A Spanish-speaking team's repository without a risk map: billing, permissions and per-company data under names the floors do not know.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_file package.json '{
  "name": "tienda",
  "private": true,
  "workspaces": ["packages/*"],
  "scripts": { "bootstrap": "npm install && npm run build --workspaces", "test": "node --test" }
}'
fx_file README.md '# Tienda

## Instalación

Corre `npm run setup` y luego `npm start`.'
fx_claude_md '# Tienda

- `packages/billingcore/`: cobros con Wompi y el libro contable (ledger). Todo cobro pasa por aquí.
- `src/cuentas/permisos.ts`: quién puede ver y editar qué dentro de una empresa.
- Cada empresa ve solo sus datos: toda consulta filtra por `empresa_id`.
- `db/migraciones/`: migraciones de Postgres, se aplican al desplegar.'
fx_file packages/billingcore/package.json '{ "name": "@tienda/billingcore", "version": "1.0.0" }'
fx_file packages/billingcore/src/wompi.ts 'export async function cobrar(referencia: string, centavos: number) {
  return { referencia, centavos, estado: "PENDIENTE" };
}'
fx_file packages/billingcore/src/ledger.ts 'export function asentar(debe: number, haber: number) { return debe - haber; }'
fx_file src/cuentas/permisos.ts 'export function puedeEditar(rol: string): boolean { return rol === "admin"; }'
fx_file src/pedidos/listar.ts 'export const listar = (empresa_id: string) => `SELECT * FROM pedidos WHERE empresa_id = ${empresa_id}`;'
fx_file db/migraciones/001_pedidos.sql 'CREATE TABLE pedidos (id serial PRIMARY KEY, empresa_id uuid NOT NULL);'
fx_commit "Estructura inicial"
