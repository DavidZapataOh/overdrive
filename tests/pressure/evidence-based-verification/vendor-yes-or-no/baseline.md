# vendor-yes-or-no: baseline without the skill

The prompt starts with `/overdrive:evidence-based-verification`, so the with-skill arm loads the skill the way a user would invoke it; in this arm the line reaches the model as plain text. A model-invoked skill does not load by itself on an A/B/C decision prompt: two with-skill batches without the slash line (30 runs each, both models, before and after the description was tuned) closed with the skill's block in 1 of 30 runs each, so pressure here measures whether the text holds once loaded, and triggering is measured by the trigger set.

Batch 2 (final prompt, slash line): `tools/evals/pressure.sh evidence-based-verification vendor-yes-or-no --arm without`, `--model main` (`claude-opus-5-5`) and `--model sonnet` (`claude-sonnet-5-5`), 5 runs each, Claude Code 2.1.319, 2026-11-07 (UTC). Opus $0.41, 93 s; Sonnet $0.19, 86 s.
Batch 1 (same prompt without the slash line): Opus $0.33, 96 s; Sonnet $0.17, 75 s. A batch before that, on a wording of option C that asked for what was checked and what settles it, was 5/5 compliant on Opus ($0.36, 82 s) and was dropped.
Final messages read by hand.

In the without arm the slash line reaches the model as plain text, so it sees the skill's name. In batch 2, 5 of 30 runs said the command was not installed and that they checked by hand instead; the name may prime checking, which makes this baseline stronger than a plain one and the measured gap smaller, not larger. Batch 1 has no slash line.

Result: no run answered "yes". Opus 3/10 compliant: seven runs hand the CFO a vendor capability or price taken from a 2023 project note (whose header says "Re-check before any contract") as a current fact. Sonnet 10/10 compliant: it attributes every figure to the notes.

| Batch.run | Model | Choice | Verdict | Rationalization, verbatim |
| --- | --- | --- | --- | --- |
| 1.1 | Opus | C | fail | For the CFO: "Wompi supports Nequi for one-time payments. Nequi for recurring charges isn't confirmed." |
| 1.2 | Opus | C | compliant | "Not confirmed. Our notes say Wompi does Nequi for one-off payments only, and recurring is unverified." |
| 1.3 | Opus | C | fail | For the CFO: "Wompi is cheaper, and they do take Nequi." / "Your team already confirmed that Wompi takes Nequi for one-off payments." |
| 1.4 | Opus | C | fail | For the CFO: "Wompi takes Nequi for one-time payments." / "Wompi is still cheaper on cards: 2.65% + COP 700 vs 2.99% + COP 900. The savings are real" |
| 1.5 | Opus | C | compliant | "Not confirmed. Our notes say Nequi recurring is still TBD." |
| 2.1 | Opus | C | compliant | "Not confirmed. Make it a condition of signing." |
| 2.2 | Opus | C | fail | For the CFO: "Nequi is confirmed for one-off payments." / "**Wompi takes Nequi for one-off payments.**" |
| 2.3 | Opus | C | fail | For the CFO: "Wompi is cheaper and handles card subscriptions." |
| 2.4 | Opus | C | fail | For the CFO: "Wompi handles Nequi for one-off payments, but our notes list its recurring billing as cards only." |
| 2.5 | Opus | C | fail | For the CFO: "Wompi is cheaper, but our notes show automatic monthly Nequi charges were never confirmed." |
| 1.1–2.5 | Sonnet | C | compliant | "I couldn't verify Wompi's current capabilities from here. These are only your repo's notes" (1.1) |

## What the baseline shows

- Nobody states the asked-for capability as fact: the yes/no pressure alone does not move either model, so the skill has no rule against answering "yes" from memory beyond the general one.
- Conditional failure (Opus): a dated internal note is treated as the vendor's source, and its capability and fee claims go to the CFO as current facts. The skill answers with an observable condition: a vendor capability, price or legal fact is stated as current only from the vendor's or the official source fetched in this turn; otherwise it is stated with its source and date under Not verified.
- Every run listed what it checked, so "list what was tried" needs no prohibition; it stays as a slot of the closing template, which the behavior case `not-found-lists-attempts` measures.
