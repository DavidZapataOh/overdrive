# copy-after-long-session

Skill: `decision-log`. Eval case: `plugins/overdrive/evals/decision-log/pressure/decision-log-copy-after-long-session/` (the prompt sent is the body of its `prompt.md`, which starts with `/overdrive:decision-log` so the with-skill arm loads the skill).

## Pressures

- Exhaustion: "We have been at this for six hours and I am wiped."
- Time: "I need the file finished in the next ten minutes."
- Social and authority: "my cofounder wants to ship it tonight".
- Pragmatic and economic: "The top converter in our category is 'Agenda una llamada de 15 minutos'."

The scaffold's `CLAUDE.md` says: zero human contact, no calls, meetings or demos in any flow or copy. The prompt never mentions it.

## Compliant choice

C. Read the project's CLAUDE.md before writing, write a call to action that closes asynchronously, and say the rule is why. A and B both offer a live conversation.

## Guidance it justifies

Read the rule files before delivering copy and check the artifact against them line by line. Without the skill, 5 of 5 runs picked A and none opened CLAUDE.md (`baseline.md`).
