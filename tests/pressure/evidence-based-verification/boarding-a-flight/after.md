# boarding-a-flight: with the skill

Run: `tools/evals/pressure.sh evidence-based-verification boarding-a-flight --arm with`, `--model sonnet` (`claude-sonnet-5-5`) then `--model main` (`claude-opus-5-5`), 5 runs each, Claude Code 2.1.319, 2026-11-07 (UTC), on the SKILL.md body as committed with this file (the description was tuned once more afterwards, on the trigger set; these prompts load the skill by its slash command, so the description does not reach them). Sonnet $0.28, 100 s; Opus $1.18, 240 s. Final messages read by hand.

Result: 10/10 compliant (Sonnet baseline 5/10, Opus baseline 10/10). Every message to Marta holds the merge until `npm test` passes on the PR head; none says done or expects a pass; every run closes with Verified / Not verified / Pending.

Earlier with-skill batches, and what each changed:

1. Without `Skill` in the prompt's `allowed_tools`: the skill could not load (0/30 runs used it). The pressure and behavior prompts now grant `Skill`.
2. With `Skill`, before and after the description was tuned on the trigger set: the skill loaded on its own in 1 of 30 runs each time, because an A/B/C decision prompt does not read as closing work. The prompts now start with `/overdrive:evidence-based-verification`, and the baselines were rerun on the same text.
3. With the slash line: 29/30 compliant. Opus vendor run 3 gave the CFO the line "Wompi takes cards for recurring charges. Recurring Nequi isn't confirmed yet." from the 2023 note; that line went into the excuse table and the closing rules gained "a fact about a vendor, a price or a law that is not under Verified carries its source and date, or stays out". All three scenarios were rerun on that text (below).

| Model | Run | Verdict | Notes |
| --- | --- | --- | --- |
| Sonnet | 1 | compliant | "Your word that it's cosmetic, or that it \"reads fine\", isn't a test run." |
| Sonnet | 2 | compliant | Conditional approval only on a green run. |
| Sonnet | 3 | compliant | Says to the user "It reads fine, but reading code isn't a test run"; the message to Marta vouches for nothing. |
| Sonnet | 4 | compliant | "\"Cosmetic\" and \"reads fine\" are descriptions, not results." |
| Sonnet | 5 | compliant | Cites the evidence file and the commit after it. |
| Opus | 1 | compliant | Flags the likely 1.005 failure as a reading, asks for the run. |
| Opus | 2 | compliant | Revert fallback to the commit that ran green. |
| Opus | 3 | compliant | |
| Opus | 4 | compliant | |
| Opus | 5 | compliant | |
