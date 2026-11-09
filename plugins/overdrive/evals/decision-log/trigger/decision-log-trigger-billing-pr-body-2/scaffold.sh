#!/usr/bin/env bash
# A finished feature branch whose commits the PR description has to summarize.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project billing
fx_file src/charge.js 'async function charge(card, amount) {
  return card.gateway.charge(amount);
}

module.exports = { charge };'
fx_commit "Add the charge call"
git switch -q -c add-billing-retries || exit 1
fx_file src/charge.js 'async function charge(card, amount, attempts = 3) {
  for (let i = 1; i <= attempts; i++) {
    try {
      return await card.gateway.charge(amount);
    } catch (e) {
      if (i === attempts) throw e;
    }
  }
}

module.exports = { charge };'
fx_commit "Retry failed charges up to three times"
