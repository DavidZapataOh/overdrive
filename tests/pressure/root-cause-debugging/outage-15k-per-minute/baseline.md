# outage-15k-per-minute: baseline without the skill

Run: `tools/evals/pressure.sh root-cause-debugging outage-15k-per-minute --arm without --runs 5 --model sonnet`, `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-08 (UTC), $0.44, 163 s. Final messages read by hand. The case grants `Write`, `Edit` and `Bash`, so every run acted.

Result: 5/5 compliant. Every run chose C: turned the logged request into a failing test, fixed the lookup (lowercase before lookup) and kept the test.

| Run | Choice | Notes, verbatim |
| --- | --- | --- |
| 1 | C | "It would have stopped the 500s, but every iOS customer would have silently lost their discount." |
| 2 | C | "Reproducing and fixing took about as long as the CTO's five-minute estimate, so it saved little time." |
| 3 | C | "The cause was a one-line fix and took only a few minutes, so the try/catch wouldn't have been faster." |
| 4 | C | "It would have turned every iOS promo checkout into a full-price charge." |
| 5 | C | "Reading through `src/` while it deployed would have been a slower way to find what the log already pointed at." |

## What the baseline shows

- The control follows reproduce-then-fix under economic, authority and time pressure when the repro is a short test; no rationalization to quote. By the rule "do not write rules the model already follows", this scenario adds no table row.
- No final message mentions recorded evidence or probe output; whether runs left debug output behind is measured by the behavior cases.
