---
name: intent-discovery
description: Turning a new feature or product idea into a decided direction before any plan or code. Use when the user wants to build, add or launch something new and non-trivial (a feature, system, dashboard) and the why or the shape is open, in any language.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *)
---

# Intent discovery

Turns an idea into a one-page skeleton that `decision-planning` plans from. `OD` means `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`. Write to the user in their language, and follow the project's CLAUDE.md and memory for tone.

## Rules

1. **Trivial work skips this skill.** When the request names the file and the change (a warning, a rename, a typo, a one-line fix), do it and write no question. Discovery is for work whose goal or shape is open.
2. **Facts are yours.** Before the first question, read what the feature touches (README, manifests, migrations, the code nearby) and run `OD recall <terms>` for rulings and learnings. Facts outside the repo (a vendor's capability or price, a law, how others do it) go to `overdrive:researcher` with a brief from `OD brief --text '<the question>'`. Never ask the user a stack, framework, database, provider, naming or "what exists today" question, nor one a decision in the log answers. Say what you found in one line instead.
3. **Ask only what only the user can decide:** taste, money, accounts, legal identity, product direction. The question also has to change what gets built. Everything else: decide it, write `Ruling: <what> — <why> — <cost if wrong>`, go on. An amount, price, reward, limit or deadline the user did not state is never filled in with a default, not even an editable one inside a plan: it is the question.
4. **The why comes first.** The first question is what the user wants to achieve and for whom, unless the request or the log already says. Nothing is built or edited during discovery.
5. **One question per message.** Never a list, never "and also". Wait for the answer; the next question comes only if the answer changed what gets built. The message ends after the recommendation line: do not announce further questions ("later I will need to know ..."), and do not add a second ask. The user's availability ("ask whatever", "I have all afternoon"), their haste ("no time for questions") or their choice of "build it now" does not change how many questions the build needs; with haste, the one question is the shortest one.
6. **Every question has the shape in** [references/questions.md](references/questions.md): what you found, one question, lettered options each with a label and what it means for the user, then `Recomiendo`/`I recommend` with the reason, worded so that "yes" accepts it.
7. **Plain language:** [references/plain-language.md](references/plain-language.md). Define a term the first time it appears, one idea per paragraph, say what each option changes for the user.
8. **Async only.** Never propose a call, meeting or demo; everything closes in writing.

| Excuse (verbatim from baseline runs) | Reality |
| --- | --- |
| "Lo que asumí (corrígeme lo que no te cuadre)" / "Es un número inventado por mí, confírmame el valor real." | An invented price or reward is a decision taken for the owner, built into code. Ask the one question, then build. |
| "Supuestos que tomé: ... $10.000 COP para cada una" followed by "Responde aprobado y lo construyo" | The same invented amount inside a plan. Asking for approval of a plan that holds your own guess is not asking. |
| "You have the afternoon and asked for questions, and an admin dashboard sits next to customer data and money, so guessing is costly." | Costly guesses are the reason for one good question, not 30. Facts come from the repo. |
| "I read the repo first so I'd only ask what it doesn't answer" followed by stack, hosting and framework questions | If the repo or the log answers it, or you can decide it and record a Ruling, it is not a question. |
| "If you only answer five, make them 1, 9, 11, 15 and 17." | You already know which questions matter. Ask that one. |
| "Si me dices también qué plataforma usa tu tienda (Shopify, WooCommerce ...)" (the repo shows a custom Express store) | Read it. A second ask in the same message is a list. |
| "Tendré que preguntarte después qué empresa de pagos usas y en qué país vendes" | Announcing the next question is a second ask. End after the recommendation line. |

## Closing: the skeleton

When no open question would change what gets built, write the skeleton to `.overdrive/run/skeleton-<slug>.md` (a path the user names wins; `<slug>` is the kebab-case feature name; create `.overdrive/run/.gitignore` containing `*` first if absent). One page, at most 40 lines:

    # Skeleton: <feature>
    Why: <the goal in the user's words>
    Decided:
    - <question> → <answer> (user | Ruling | D-NNNN)
    Shape: <3 to 6 plain-language lines: what gets built>
    Not covered: <what this leaves out or has not been decided, each with who settles it>
    Next: decision-planning

The file keeps these English labels, because `decision-planning` reads them. The closing message gives the same content in the user's language, in short paragraphs (see plain language), with the file path, and ends with the line `Next: decision-planning`, which hands the skeleton on. An answer that is a lasting rule goes to the decision log through `overdrive:decision-log`.
