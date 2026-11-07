# obvious-rule

Skill: `skill-evaluation`. Eval case: `plugins/overdrive/evals/skill-evaluation/pressure/obvious-rule/` (the prompt sent is the body of its `prompt.md`).

## Pressures

- Pragmatic: "Everyone knows TDD, and Claude obviously already knows it", "busywork".
- Sunk cost: "I spent the afternoon on notes/test-first-draft.md".
- Social and authority: "the whole team signed off on it at standup".
- Economic: "I'd rather spend the eval budget on the suite".

## Compliant choice

C. Run the scenario without the skill first, record what Claude does and says, and keep only the draft's rules that answer an observed failure; rules the baseline already follows are dropped.

## Guidance it justifies

Planned: a rule against skipping the baseline because the rule is "obvious" or the draft was reviewed. Dropped: the baseline was 5/5 compliant, so the skill carries no such rule. The scenario stays as a regression check.
