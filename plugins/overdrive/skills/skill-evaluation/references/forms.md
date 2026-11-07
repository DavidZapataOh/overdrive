# Instruction forms

Pick the form from what the baseline did, not from how important the rule feels. A form that does not match the failure is rationalized away or makes the failure worse: a prohibition aimed at a shape problem produces more of the unwanted shape than a recipe does, and a single nuance clause added to a recipe that works turns consistent output into noisy output.

| Baseline failure | Form | Not this |
| --- | --- | --- |
| Knows the rule, skips it under pressure | Prohibition, a table of the verbatim excuses, red flags | "Prefer", "consider", "try to" |
| Complies, but the output has the wrong shape | A recipe or template stating what the output is | A list of things not to write |
| Leaves out a required element | A required slot in the template | A reminder in prose |
| Right behavior depends on a condition | A condition on something observable | A rule plus exemption clauses |

## Knows the rule, skips it under pressure

Baseline: "Normally I'd write the test first, but the user said it's a one-line fix, so I'll add the test after."

```markdown
No production code without a failing test first. Size is not an exception.

| Excuse | Reality |
| --- | --- |
| "it's a one-line fix, I'll add the test after" | One-line fixes are where untested regressions hide. Test first. |
| "the user said there's no time" | Writing the test is part of the fix, not extra time. |
```

The excuses in the table are quoted from `baseline.md`, never invented. A row nobody said is noise.

## Complies, but the output has the wrong shape

Baseline: the commit messages exist but use past tense and no body. A list of bans ("don't use past tense, don't skip the body") anchors on the wrong shape. State the shape:

```markdown
Every commit message is:

    <imperative verb> <what>, 72 characters or fewer
    (blank line)
    <why the change was needed>
```

## Leaves out a required element

Baseline: reports are fine except that 4 of 5 omit the model used. Make it a slot that cannot be skipped without leaving a visible hole:

```markdown
End with:

    Model: <model ID>
    Cost: <USD>
```

## Right behavior depends on a condition

Baseline: the agent either always or never asks before running migrations. "Ask unless it is safe" lets the agent decide what "safe" means. Key the rule to something it can check:

```markdown
If the diff touches `migrations/` or any file containing `DROP`, stop and ask before running it. Otherwise run it.
```

## No nuance clauses

"Write the test first unless it's trivial", "where appropriate", "if it matters": each one hands the decision back to the judgment the baseline showed failing. If a real exception exists, write it as an observable condition (last section), or leave it out.
