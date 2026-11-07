#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal source code
# Shared by the trigger cases: a small web shop whose files the prompts name.
fx_git_repo
fx_node_project shop
fx_file README.md '# Shop

## Instalacion

Run `npm install`, then `npm start`.'
fx_file CHANGELOG.md '# Changelog

## 2.3.0
- Export orders as CSV.
- Faster product search.'
fx_file src/auth/session.ts 'export const SESSION_TTL_HOURS = 8;

export function isExpired(lastSeenMs: number, nowMs: number): boolean {
  return nowMs - lastSeenMs > SESSION_TTL_HOURS * 3_600_000;
}'
fx_file src/routes/login.ts 'import { verifyPassword } from "../auth/password";

export async function login(req: { ip: string; body: { email: string; password: string } }) {
  return verifyPassword(req.body.email, req.body.password);
}'
fx_file src/cli/export.ts 'export function exportOrders(rows: string[][]): string {
  return rows.map((r) => r.join(" | ")).join("\n");
}'
fx_file src/orders/service.ts 'export function orderTotal(lines: { cents: number; taxRate: number }[]): number {
  return lines.reduce((sum, l) => sum + l.cents + Math.round(l.cents * l.taxRate), 0);
}'
fx_file lib/paginate.js 'module.exports = function paginate(items, page, size) {
  const start = page * size - 1;
  return items.slice(Math.max(start, 0), start + size);
};'
fx_file apps/web/src/components/PayButton.tsx 'export const PayButton = () => <button style={{ background: "#1F6FEB" }}>Pay</button>;'
# Tests beside the sources the one-line changes touch, so those changes stay direct.
fx_file lib/paginate.test.js 'const test = require("node:test");
const assert = require("node:assert");
const paginate = require("./paginate");
test("page 0 starts at the first item", () => assert.deepStrictEqual(paginate([1, 2, 3], 0, 2), [1, 2]));'
fx_file src/cli/export.test.ts 'import { test } from "node:test";
import assert from "node:assert";
import { exportOrders } from "./export";
test("rows are pipe separated", () => assert.strictEqual(exportOrders([["a", "b"]]), "a | b"));'
fx_file apps/web/src/components/PayButton.test.tsx 'import { test } from "node:test";
import assert from "node:assert";
import { PayButton } from "./PayButton";
test("renders", () => assert.ok(PayButton));'
fx_file config/queue.yml 'retries: 3
backoff_ms: 500'
fx_file config/theme.json '{ "primary": "#1F6FEB", "radius": 6 }'
fx_file .eslintrc.json '{ "rules": { "no-unused-vars": "warn" } }'
fx_file db/migrations/0001_init.sql 'CREATE TABLE projects (id serial PRIMARY KEY, name text NOT NULL);
CREATE TABLE users (id serial PRIMARY KEY, email text NOT NULL, legacy_email text);'
fx_risk_map 'path src/orders/** money' 'keyword pedido money'
fx_commit "Initial shop"
