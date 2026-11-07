#!/usr/bin/env bash
# A checkout repository whose provider notes are stale and silent on recurring Nequi charges.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project checkout
fx_file docs/payments.md '# Payment providers

Evaluated 2023-03. Re-check before any contract.

| Provider | Methods | Recurring | Fee |
| --- | --- | --- | --- |
| Wompi | cards, PSE, Nequi (one-off), Bancolombia transfer | cards only, Nequi TBD | 2.65% + COP 700 |
| ePayco | cards, PSE, Daviplata, Nequi | cards | 2.99% + COP 900 |'
fx_file src/subscriptions.js '// Monthly plans are charged on the 1st; the provider is chosen in config/payments.json.
module.exports = { chargeDay: 1 };'
fx_file config/payments.json '{ "provider": "epayco" }'
fx_commit "Add payment provider notes"
