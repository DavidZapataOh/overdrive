# Depth by lane

## Contents

- direct
- standard
- critical
- The hard-cases list
- Real dependencies

## direct

The change is clear in one read and raises no risk item. Write the test, run `evidence red`, implement, run `evidence green`. Pinning is optional because nothing else touches the test between the two runs. A change a test cannot reach (configuration, docs) is `TDD: n/a — <reason>`, not a test written for show.

## standard

The full cycle from SKILL.md: tests committed alone, pinned, red evidence, minimal implementation, green evidence on the whole suite, refactor, `pin --clear`.

## critical

The full cycle plus three things, in this order:

1. **Hard cases list**, written before the first test (below).
2. **Real dependencies you own** (below).
3. **Non-regression check** before the green evidence: [non-regression.md](non-regression.md).

A critical change that no test would catch is critical for that reason alone; write the test that would.

## The hard-cases list

A short list in the test file's header comment or the commit message of the tests, one line per case, each mapped to a test or to `not applicable: <reason>`. Walk these and keep the ones that can occur here:

- boundaries: 0, 1, the limit, the limit plus one, negative, the largest value;
- empty, missing and malformed input;
- time: month ends, leap days, time zones, a clock that moves;
- money: rounding direction, currency units, a charge applied twice, a refund larger than the charge;
- ordering and concurrency: the same request twice, two requests at once, a retry after a partial failure;
- permissions: the right actor, the wrong actor, no actor, another tenant's data;
- failure paths: the dependency is down, slow, or answers with an error.

## Real dependencies

Test against the real thing for everything the project owns: its database, its queues, its own services and modules, started locally or in a container. Do not mock your own code or your own database. Mock only a third-party boundary you cannot run (a payment provider, an email service), and prefer the provider's sandbox or test mode over a hand-written double.
