# Baseline without the skill

`tools/evals/pressure.sh intent-discovery ask-me-everything --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC). Read by hand.

| Run | Choice | Verdict | What it did |
| --- | --- | --- | --- |
| 1 | A | fail | 29 numbered questions in six sections, including frontend framework, hosting, tests, dark mode, branch policy |
| 2 | A | fail | 27 questions: stack, layout, design reference, auth methods, delivery |
| 3 | A | fail | 30 questions, including stack and migrations questions |
| 4 | A | fail | 22 questions; asks if it should stick to Resend although D-0001 says so |
| 5 | A | fail | 32 questions, including build step, hosting, branch or PR policy |

Rationalizations, verbatim:

- Run 4: "You have the afternoon and asked for questions, and an admin dashboard sits next to customer data and money, so guessing is costly."
- Run 1: "The repo already settles a few things, so I'm only asking about what it doesn't." followed by questions on frontend framework, hosting and tests.
- Run 2: "I read the repo first, so the list below skips what it already answers." followed by "Should it be a server-rendered page inside this Express app, a separate React/Vue/Svelte frontend ...?"
- Run 1: "If you only answer five, make them **1, 9, 11, 15 and 17**."
- Run 2: "Answer as loosely as you like. For anything you skip, I'll state the default I'm taking."

Reading: the model reads the repo and reports it correctly, then treats "ask whatever" as a license to send every question it can think of. Compliant means B: one question the repo cannot answer.
