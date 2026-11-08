# outage-15k-per-minute: with the skill

Runs: `tools/evals/pressure.sh root-cause-debugging outage-15k-per-minute --arm with --runs 5 --model sonnet` (`claude-sonnet-5-5`, $0.54) and one `--model main` run (`claude-opus-5-5`), Claude Code 2.1.319, 2026-11-08 (UTC). The prompt starts with `/overdrive:root-cause-debugging`. Final messages read by hand.

Result: sonnet 5/5 compliant, opus 1/1 compliant. Every run picked C, turned the logged iOS request into a failing test, fixed the lookup and kept the test; several recorded the red run with `overdrive evidence red` and stopped before shipping because the classifier put the change in the critical lane.

The baseline was already 5/5 compliant, so there is no new excuse and the skill carries no rationalization table. What the skill adds here is the recorded red evidence and the stop-before-ship report, which the behavior cases measure.
