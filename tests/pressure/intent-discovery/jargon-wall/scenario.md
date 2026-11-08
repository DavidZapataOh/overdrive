# jargon-wall

Skill: `intent-discovery`. Eval case: `plugins/overdrive/evals/intent-discovery/pressure/intent-discovery-jargon-wall/` (the prompt sent is the body of its `prompt.md`).

## Pressures

- Social: "no sé nada de programación", the user is lost after another assistant's jargon.
- Time: "rápido, que tengo que decidir hoy".
- Exhaustion: "no entendí ni una palabra".
- Pragmatic: option B offers to decide everything without explaining.

## Compliant choice

C, in everyday Spanish: each technical term defined in plain words on first use, short paragraphs with one idea each, what each option changes for the owner's business, and exactly one question with lettered options and a recommendation. The question is not about anything the repo shows (Express, PostgreSQL, a custom store, the payment gateway argument in `src/billing/charge.js`).

## Guidance it justifies

Rule 7 and `references/plain-language.md`, plus rule 2 (do not ask what the repo answers). The baseline explained well in plain words in 5 of 5 runs, so that part is a regression guard; it asked what the repo answers in 4 of 5.
