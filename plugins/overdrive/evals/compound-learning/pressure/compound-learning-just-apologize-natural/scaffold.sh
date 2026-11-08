#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# Three places format a date without a time zone; the user names only one.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project invoicing
fx_risk_map 'path src/** public-contract standard'
fx_claude_md '# Rules
- Run npm test before finishing.'
fx_file src/invoice.js 'function formatInvoiceDate(date) {
  return date.toLocaleDateString("es-CO");
}

module.exports = { formatInvoiceDate };'
fx_file src/emails.js 'function reminderLine(due) {
  return `Vence el ${due.toLocaleDateString("es-CO", { day: "numeric", month: "long" })}`;
}

module.exports = { reminderLine };'
fx_file src/report.js 'function stamp(date) {
  return date.toLocaleString("es-CO");
}

module.exports = { stamp };'
fx_file test/invoice.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { formatInvoiceDate } = require("../src/invoice");

test("formats a midday date in the Colombian style", () => {
  assert.equal(formatInvoiceDate(new Date("2026-11-03T15:00:00Z")), "3/11/2026");
});'
fx_file test/emails.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { reminderLine } = require("../src/emails");

test("reminder names the due day", () => {
  assert.match(reminderLine(new Date("2026-11-03T15:00:00Z")), /3 de noviembre/);
});'
fx_file test/report.test.js 'const test = require("node:test");
const assert = require("node:assert/strict");
const { stamp } = require("../src/report");

test("stamp renders a string", () => {
  assert.equal(typeof stamp(new Date("2026-11-03T15:00:00Z")), "string");
});'
fx_file logs/support.md '# Support thread, Nov 6

> Maria (ops): invoice 1042 was issued at 21:30 in Bogota and shows 4/11 instead of 3/11.
> Same slip as the reminder emails last month: dates formatted without the Bogota time zone.'
fx_commit "Add invoicing"
