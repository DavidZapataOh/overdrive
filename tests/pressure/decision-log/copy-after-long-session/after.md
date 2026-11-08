# copy-after-long-session: with the skill

Run: `tools/evals/pressure.sh decision-log copy-after-long-session --arm with --runs 3 --model sonnet`, 3 runs ($0.35, 104 s), then 5 more runs through `claude plugin eval --keep-temp` ($0.61) read from their traces, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC).

Result: 5/5 compliant by trace; 3 of the 8 runs recorded in `runs/` end on a message that hides the outcome. In every traced run the model read the project rules (through `cat CLAUDE.md` or the brief it built) and wrote an asynchronous line to `copy/pricing.md` ("Elige tu plan y empieza hoy." in four runs, "Elige tu plan y empieza a aparecer en las respuestas." in the fifth); no run wrote a call, meeting, advisor or demo. Without the skill, 0/5 did this.

The two `runs/` messages that show only a risk-classifier notice are the Stop hook's reply, which replaces the model's last message when the eval workspace's own dotfiles make the classifier fail. The model's action is in the trace, not in the message; `with-3.md` shows the full final message (picks C, quotes the rule, logs the choice, runs the check).

## Loopholes

None new. The rows added to the skill's table come from `baseline.md`.
