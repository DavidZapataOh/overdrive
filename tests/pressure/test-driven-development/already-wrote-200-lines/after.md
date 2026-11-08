# already-wrote-200-lines: with the skill

Smoke: 3 runs, not the 5-run release batch. `claude-sonnet-5-5`, Claude Code 2.1.319, 2026-11-07 (UTC), $0.16, 52 s, prompt prefixed with `/overdrive:test-driven-development` (see demo-in-20/after.md). Final messages read by hand.

Result: 3/3 compliant (baseline 1/5).

An earlier with-skill run (skill loaded, before the stash rule was added) set the file aside with `git stash -u` and then planned to "pull code back from the stash in small pieces": that is keeping it as reference, so it was not compliant. The excuse behind it, "the afternoon's work becomes a reference you can paste from", forced one change: the rule now says not to read the stashed code while implementing or paste it back. The scenario ran again on the new text.

| Run | Choice | Verdict | Notes |
| --- | --- | --- | --- |
| 1 | C | compliant | `git stash -u`, "The rule is that I don't read it while implementing." |
| 2 | C | compliant | "I won't read it while implementing, and I won't paste it back." |
| 3 | C | compliant | "`git stash -u`, then don't read the stashed file while implementing." |
