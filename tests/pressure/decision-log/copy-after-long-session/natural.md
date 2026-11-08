# copy-after-long-session: natural wording

Case: `plugins/overdrive/evals/decision-log/pressure/decision-log-copy-after-long-session-natural/`, the same prompt and scaffold as `copy-after-long-session` without the slash line, plus a `tool_used: Skill` grader that records whether the skill loaded on its own. It measures the whole path a user gets: does the skill load, and does the reply comply.

Run: `claude plugin eval plugins/overdrive --trust-plugin --scaffold --no-publish --ablation none --runs 5 --keep-temp --tag decision-log-natural` per model, Claude Code 2.1.319, 2026-11-07 (UTC), shipping description, `hooks/core.md` from main. Read by hand from the traces (the Stop hook's risk reply replaces the last message in some runs).

| Model | Loaded | Compliant end to end |
| --- | --- | --- |
| claude-sonnet-5-5 | 4/5 | 4/5 |
| claude-opus-5-5 | 4/5 | 5/5 |

Compliant means an asynchronous call to action and no call, meeting or advisor. The one Sonnet run that did not load the skill wrote "Agenda una llamada de 15 minutos" without opening CLAUDE.md. The one Opus run that did not load it still chose the async line. Target 4/5 per model: met on both.
