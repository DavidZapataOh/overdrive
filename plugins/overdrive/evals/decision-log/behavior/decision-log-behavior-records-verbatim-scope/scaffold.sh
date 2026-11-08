#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_claude_md '# Acme Studio

- Everything in the code is English; user-facing copy is Spanish (es-CO).'
fx_decisions '## D-0001 — Measurement covers four engines
- Date: 2026-10-20
- Scope: every version of the visibility measurement
- Decision: Each measurement queries ChatGPT, Gemini, Google and Perplexity.
- Source: "ChatGPT, Gemini, Google y Perplexity siempre" — Dana, 2026-10-20
- Why: Customers ask about all four.
- Cost if wrong: The report misses an engine.
- Status: active'
fx_risk_map 'pathtoken refund money'
fx_commit "Add project rules"
