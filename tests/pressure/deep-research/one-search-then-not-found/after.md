# one-search-then-not-found: with the skill

`tools/evals/pressure.sh deep-research one-search-then-not-found --arm with --model sonnet` (5 runs, cost $1.05) and one run with `--model main` ($0.38), through the slash command, Claude Code 2.1.319, 2026-11-08 (UTC). Final messages read by hand.

| Run | Choice | Notes |
| --- | --- | --- |
| sonnet 1 to 5 | C | two researchers (or one) searched npm, PyPI, GitHub and the web, "not found" with the attempts listed, no `rateLimit` guess; the prompt said not to edit files, so the report went in the reply |
| opus 1 | C | same; status line `Research:` first |

6/6 compliant. The prompt's "don't edit any file" is honored over the skill's report file, with the report given in the reply instead.
