#!/usr/bin/env bash
# Provider notes that do not answer the question; no web tool is granted in this case.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project checkout
fx_file docs/payments.md '# Payment providers

Evaluated 2023-03. Re-check before any contract.

| Provider | Methods | Recurring | Fee |
| --- | --- | --- | --- |
| Wompi | cards, PSE, Nequi (one-off), Bancolombia transfer | cards only, Nequi TBD | 2.65% + COP 700 |'
fx_commit "Add payment provider notes"
