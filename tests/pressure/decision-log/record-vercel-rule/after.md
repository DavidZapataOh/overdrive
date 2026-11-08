# record-vercel-rule: with the skill

Run: `tools/evals/pressure.sh decision-log record-vercel-rule --arm with --runs 3 --model sonnet`, 3 runs, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.24, 66 s. Final messages read by hand.

Result: 3/3 compliant (baseline 3/5). Each run wrote D-0002 with "No Vercel Pro until sale 10" as the source, scope Vercel Pro only, "not stated" for Why and Cost if wrong, ran `decisions check`, named the team's other two services as open and asked a one-line question for each. No run touched CLAUDE.md. Runs 2 and 3 write `user` as the author instead of an invented title.

## Loopholes

None.
