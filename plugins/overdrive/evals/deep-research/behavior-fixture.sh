#!/usr/bin/env bash
# Sourced by the behavior scaffolds: a small SaaS repository whose rules name the research tools.
# shellcheck source=../_lib/fixtures.sh
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1

research_project() {
  fx_git_repo
  fx_node_project acme-ranker
  fx_file README.md '# Acme Ranker

Ranking API for a marketplace. A team of four, one Postgres database of about 50 GB, EU region, bursty traffic.'
  fx_claude_md '# Acme Ranker

Research rules: find pages with WebSearch and read them with WebFetch. Prefer the vendor'"'"'s own documentation and pricing pages. Cite the URL of every claim.'
  fx_risk_map 'path .github/** delivery'
  fx_commit "Add project readme and rules"
}
