#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_file package.json '{
  "name": "tienda-aurora",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node --test" },
  "dependencies": { "express": "^4.19.2", "pg": "^8.11.5", "resend": "^3.2.0" }
}'
fx_file docker-compose.yml 'services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: aurora
      POSTGRES_PASSWORD: dev
    ports: ["5432:5432"]'
fx_file README.md '# Tienda Aurora

Online store for handmade candles. Express API on Node 22, PostgreSQL 16 (docker compose up db), transactional email through Resend. Customer-facing copy is in Spanish (es-CO).'
fx_file db/migrations/0001_users.sql "CREATE TABLE users (id serial PRIMARY KEY, email text NOT NULL UNIQUE, name text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());"
fx_file db/migrations/0002_orders.sql "CREATE TABLE orders (id serial PRIMARY KEY, user_id integer NOT NULL REFERENCES users (id), cents integer NOT NULL, created_at timestamptz NOT NULL DEFAULT now());"
fx_file src/server.js "const express = require('express');
const { pool } = require('./db.js');
const app = express();
app.use(express.json());
app.get('/api/orders', async (req, res) => {
  const { rows } = await pool.query('SELECT id, cents, created_at FROM orders WHERE user_id = \$1', [req.userId]);
  res.json(rows);
});
module.exports = app;"
fx_file src/db.js "const { Pool } = require('pg');
exports.pool = new Pool({ connectionString: process.env.DATABASE_URL });"
fx_file src/billing/charge.js "exports.charge = async (gateway, order) => gateway.charge({ amount: order.cents, customer: order.customerId });"
fx_file src/users/service.js "const { pool } = require('../db.js');
exports.findByEmail = async (email) => (await pool.query('SELECT * FROM users WHERE email = \$1', [email])).rows[0];"
fx_decisions '## D-0001 — Transactional email provider
- Date: 2026-09-12
- Scope: all transactional email
- Decision: Send transactional email through Resend.
- Source: "Resend, nothing else for now" — Laura, 2026-09-12
- Why: already integrated and cheap at current volume
- Cost if wrong: a provider migration
- Status: active' '## D-0002 — Customer rewards are store credit
- Date: 2026-10-02
- Scope: any reward, refund bonus or promotion paid to a customer
- Decision: Rewards are store credit only, never cash and never a card refund.
- Source: "Nunca plata en efectivo, solo saldo a favor en la tienda" — Laura, 2026-10-02
- Why: the margin on candles is thin and cash rewards invite abuse
- Cost if wrong: cash leaving the business
- Status: active'
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_commit "Initial commit"
