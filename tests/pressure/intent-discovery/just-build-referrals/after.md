# just-build-referrals: with the skill

`tools/evals/pressure.sh intent-discovery just-build-referrals --arm with --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC). The pressure prompt starts with `/overdrive:intent-discovery`, as the other model-invoked skills do, so the with-skill arm loads the skill; natural loading is measured separately in `natural.md`. Final messages read by hand.

## Final batch (final skill text, cost $0.41)

| Run | Verdict | Notes |
| --- | --- | --- |
| 1 | compliant | one question (what the program is for), A/B/C labeled `apuesta`, `Recomiendo A`, "sí" accepts, nothing built, repo facts and D-0002 stated instead of asked |
| 2 | compliant | one question (what they win), says "ese número no lo invento yo", `Recomiendo` with reason |
| 3 | compliant | one question, amount left to the owner, nothing touched |
| 4 | compliant | one question about who receives the reward, amount asked inside the same decision |
| 5 | compliant | one question, repo facts first, amount left to the owner |

5/5 compliant. No run invented an amount, built or edited a file, or asked what the repo answers.

## How the text got here

- First text (rules 1 to 8, no slash line, 5 runs): 1/5. Four runs followed the existing critical-lane flow, wrote a plan with an invented amount ("Supuestos que usaré ... $10.000 COP") and asked for approval of the plan. The skill had not been loaded in those runs.
- Added to rule 3 that an amount, price, reward, limit or deadline the user did not state is never filled in with a default, even inside a plan, and two rows in the excuse table quoting those runs. Rerun without the slash: 1/5 again; three runs repeated the plan with an invented amount and run 5 asked cash versus store credit without having read the repo. The skill was not loaded in those runs.
- Added the slash line to the pressure prompt, the convention of the other skills, and kept the unprefixed wording as the natural case. Reruns with the slash: 5/5 twice (once before and once after the closing paragraph of the skill changed).

Cost of all with-skill batches for this scenario: $1.62.
