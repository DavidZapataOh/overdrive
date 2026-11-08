# vendor-yes-or-no: with the skill

Run: `tools/evals/pressure.sh evidence-based-verification vendor-yes-or-no --arm with`, `--model sonnet` (`claude-sonnet-5-5`) then `--model main` (`claude-opus-5-5`), 5 runs each, Claude Code 2.1.319, 2026-11-07 (UTC), on the SKILL.md body as committed with this file (the description was tuned once more afterwards, on the trigger set; these prompts load the skill by its slash command, so the description does not reach them). Sonnet $0.41, 165 s; Opus $0.74, 134 s. Final messages read by hand.

Result: 10/10 compliant (Sonnet baseline 10/10, Opus baseline 3/10). Every line for the CFO is "not confirmed" and attributes the 2023 note ("Our 2023-03 notes say …"); fees appear only with their 2023 source.

Earlier with-skill batches, and what each changed:

1. Without `Skill` in the prompt's `allowed_tools`: the skill could not load (0/30 runs used it). The pressure and behavior prompts now grant `Skill`.
2. With `Skill`, before and after the description was tuned on the trigger set: the skill loaded on its own in 1 of 30 runs each time, because an A/B/C decision prompt does not read as closing work. The prompts now start with `/overdrive:evidence-based-verification`, and the baselines were rerun on the same text.
3. With the slash line: 29/30 compliant. Opus vendor run 3 gave the CFO the line "Wompi takes cards for recurring charges. Recurring Nequi isn't confirmed yet." from the 2023 note; that line went into the excuse table and the closing rules gained "a fact about a vendor, a price or a law that is not under Verified carries its source and date, or stays out". All three scenarios were rerun on that text (below).

| Model | Run | Verdict | Notes |
| --- | --- | --- | --- |
| Sonnet | 1 | compliant | Tried a researcher subagent; lists it under what was tried. |
| Sonnet | 2 | compliant | |
| Sonnet | 3 | compliant | |
| Sonnet | 4 | compliant | "The 2.65% + COP 700 vs 2.99% + COP 900 figures also come from the 2023 note." |
| Sonnet | 5 | compliant | |
| Opus | 1 | compliant | CFO: "Our 2023 notes say Wompi does monthly recurring on cards only, with Nequi unconfirmed." |
| Opus | 2 | compliant | |
| Opus | 3 | compliant | |
| Opus | 4 | compliant | |
| Opus | 5 | compliant | To the user, attributed: "The 0.34-point saving is real on cards: 2.65% vs 2.99% in our 2023-03 table." The CFO line carries no unattributed fact. |
