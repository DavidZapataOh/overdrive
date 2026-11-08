---
name: root-cause-debugging
description: Use when behavior is wrong or broke and the cause is unknown, or someone asks what went wrong: a failing test, wrong totals or output, a 500 in production, something that worked before, a flaky run. Not for adding logging, debug settings, explaining traces or tests for new features.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/bin/overdrive *)
---

# Root-cause debugging

No fix and no theory before a command that fails now and would pass once the bug is fixed. A deadline, an outage, a cost per minute and someone's confident diagnosis do not change that order; that command is also the quickest way to test the diagnosis.

`overdrive` is `${CLAUDE_PLUGIN_ROOT}/bin/overdrive`; it is not on the Bash PATH, so call it by that path.

## The steps

1. **Make it fail on demand.** Turn the report into a command: a test through the public interface at the seam where the bug lives, built from the real input (the logged request, the failing row, the exact arguments). Record it: `${CLAUDE_PLUGIN_ROOT}/bin/overdrive evidence red -- <command>`. The failure must be the reported symptom, not a syntax error or a missing import. Recipes for flaky, production-only and environment cases: [references/feedback-loop.md](references/feedback-loop.md).
2. **Rank 3 to 5 hypotheses.** Each names the cause and the observation that would rule it out; the most likely goes first. Nobody's certainty counts as an observation. Template and ranking: [references/hypotheses.md](references/hypotheses.md).
3. **Probe one variable at a time.** Temporary output carries the tag `[DEBUG-xxxx]`, four hex characters chosen once per session. Redact secrets, tokens and personal data from anything printed or pasted. Change nothing else between two probes.
4. **Fix the root.** Change the line where the wrong value is produced, not the line where it shows up. A clamp, a try/catch with a fallback, a filter on bad values, a special case for the failing input, `|| 0`, a longer timeout or more retries hides the bug and does not count as a fix.
5. **Keep the regression test.** The step 1 command becomes the test, through `overdrive:test-driven-development`. If no seam can reach the bug, say so: that is a finding, and the report names it.
6. **Clean up and prove it.** `grep -rn '\[DEBUG-' .` prints nothing, then `${CLAUDE_PLUGIN_ROOT}/bin/overdrive evidence green -- <full test command>`.

## Stop rules

- Three fixes that did not make the command pass: stop. List what each assumed and why it was wrong, say which layer or design the evidence now questions, and ask before a fourth.
- An environment that will not run the code (a service, credentials, a missing dataset): about 10 minutes, then escalate with exactly what is needed. Do not theorize in its place.
- The failing input is not available (no log, no request, no steps): that is the first finding. Ask for it; do not guess a cause.

## Close

End with `Root cause: <file:line> — <why it produced the symptom>` and `Debug: red <evidence file> → green <evidence file>`.
