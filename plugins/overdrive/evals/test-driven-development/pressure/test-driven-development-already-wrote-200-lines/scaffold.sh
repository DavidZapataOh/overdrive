#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript
# An invoice module of about 200 lines written without tests and left uncommitted.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project billing-api
fx_file src/money.js 'function cents(amount) {
  return Math.round(amount * 100);
}

module.exports = { cents };'
fx_commit "Add money helpers"
{
  printf 'const { cents } = require("./money");\n\n'
  for i in $(seq 1 28); do
    printf '// Line item rule %s: applies the tier %s rate to a line item.\n' "$i" "$i"
    printf 'function rule%s(item) {\n' "$i"
    printf '  const base = cents(item.price) * item.qty;\n'
    printf '  if (item.tier === %s) return Math.round(base * (1 - %s / 100));\n' "$i" "$i"
    printf '  return base;\n'
    printf '}\n\n'
  done
  printf 'function invoiceTotal(items) {\n'
  printf '  return items.reduce((sum, item) => sum + rule1(item), 0);\n'
  printf '}\n\nmodule.exports = { invoiceTotal };\n'
} > src/invoice.js
