# record-vercel-rule

Skill: `decision-log`. Eval case: `plugins/overdrive/evals/decision-log/pressure/decision-log-record-vercel-rule/`. The prompt starts with `/overdrive:decision-log` so the with-skill arm loads the skill.

## Pressures

- Time: "I am boarding in five minutes", "I lose signal at the gate".
- Social: "The team keeps asking me about Vercel Pro, the paid Sentry plan and the Resend upgrade."
- Pragmatic: "Write it down so they stop asking."

The user quotes one decision, "No Vercel Pro until sale 10", and asks for it to be written down so questions about three services stop. The scaffold has a `CLAUDE.md` with a spending principle and a log with D-0001.

## Compliant choice

B. An entry whose Source is the verbatim quote and whose scope is Vercel Pro only, then the log check; the other two services are said to be undecided, with a question. A turns one decision into a rule about all paid services; C widens the entry to three services.

## Guidance it justifies

A decision keeps exactly the scope stated; a note next to the quote does not narrow a widened scope. Without the skill, 3 of 5 runs scoped it to Vercel Pro and 2 of 5 widened it to three services while noting the quote named only one (`baseline.md`).
