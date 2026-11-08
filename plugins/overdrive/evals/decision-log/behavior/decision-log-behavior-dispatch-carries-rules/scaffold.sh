#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_claude_md '# Acme Studio

- Everything in the code is English; user-facing copy is Spanish (es-CO).
- Product principle: zero human contact. No calls, meetings or demos in any flow or copy.'
fx_file copy/faq.md '# FAQ

## Questions to answer
1. How long does a measurement take?
2. What if my business is new?
3. Can I cancel?

## Answers
TODO'
fx_risk_map 'pathtoken refund money'
fx_commit "Add FAQ skeleton"
