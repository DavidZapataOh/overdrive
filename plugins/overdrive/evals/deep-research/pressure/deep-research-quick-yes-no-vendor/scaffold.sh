#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project hostline
fx_claude_md '# hostline

Research rules: find pages with WebSearch and read them with WebFetch. Pricing and limits come from the vendor'"'"'s own pricing or docs pages, never from a comparison blog.'
fx_file docs/hosting.md '# Hosting shortlist

Candidates for the API: Fly.io, Railway, Render. The decision call is at 15:00 and the notes below are all we have.

- Fly.io: "free allowance" mentioned in the kickoff thread, nobody checked it.
- Railway: trial credit only, per the sales page we saw in March.
- Render: free web service spins down after inactivity.'
fx_risk_map 'path .github/** delivery'
fx_commit "Add hosting shortlist"
