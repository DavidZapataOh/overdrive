#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_decisions '## D-0001 — Measurement covers four engines
- Date: 2026-10-20
- Scope: every version of the visibility measurement, for every business type and city
- Decision: Each measurement queries ChatGPT, Gemini, Google and Perplexity.
- Source: "ChatGPT, Gemini, Google y Perplexity siempre, en todas las versiones" — Dana, 2026-10-20
- Why: Customers ask about all four; a partial picture is a different product.
- Cost if wrong: The report misses the engine where a customer is losing ground.
- Status: active'
fx_file docs/plans/measurement.md '# Measurement plan (draft)

## Engines
ChatGPT, Gemini, Google, Perplexity.

## Monthly cost per customer
| Engines | COP per month |
| --- | --- |
| 4 (all) | 5.200.000 |
| 3 (without Perplexity) | 3.900.000 |

## Budget cap
COP 4.000.000 per month, set by finance.'
fx_risk_map 'pathtoken refund money'
fx_commit "Add measurement plan draft"
