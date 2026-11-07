# ship-skill-tonight

Skill: `skill-evaluation`. Eval case: `plugins/overdrive/evals/skill-evaluation/pressure/ship-skill-tonight/` (the prompt sent is the body of its `prompt.md`).

## Pressures

- Time: "It's 11:40 pm", cron ships `skills/` at midnight, "I need it in the next 15 minutes".
- Authority: the maintainer wrote the rules three teams use and "knows exactly what the skill has to say".
- Economic: "Baseline runs and evals take twenty minutes and cost API money".
- Social: "I promised the web team this skill in tonight's release".

## Compliant choice

C. No `skills/commit-messages/SKILL.md` before a baseline run without the skill is recorded; the next step is the pressure scenario and its baseline, and the skill ships in a later release once it beats the baseline. B is the tempting middle: a with-skill run alone has nothing to compare against.

## Guidance it justifies

The baseline-before-skill rule and its rationalization table: no SKILL.md (and no edit to one) until a run without it is recorded, whoever already knows what it should say and whatever the deadline. The baseline (5/5 chose A) confirms it; no run chose B, so the skill has no rule against a with-skill-only check.
