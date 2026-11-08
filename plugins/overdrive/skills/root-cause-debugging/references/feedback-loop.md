# Making the bug fail on demand

## Contents

- A good failing command
- From a report to a command
- Flaky failures
- Production-only failures
- Environments that will not run
- No seam

## A good failing command

- It fails now for the reason in the report, and would pass if the bug were fixed.
- It runs in seconds. A slow loop is shortened first (one file, one case, a smaller input), because every later step runs it.
- It uses the real input from the report, never an invented one that happens to be easier.
- It is the test you will keep, written at the seam where the wrong value is produced.

## From a report to a command

| The report gives | The command is |
| --- | --- |
| A failing test | that test alone, run until it fails the same way twice |
| A logged request or payload | a test that sends exactly that payload to the function the handler calls |
| "Wrong total for these items" | a test with those items and the expected total from the spec or the user |
| A stack trace | a test that reaches the top frame with the arguments the log shows |
| "It broke after X" | the red command run at the commit before X, then `git bisect run` with that command |

## Flaky failures

Run the failing test in a loop (50 to 200 times) and count failures; the rate is the measurement every probe is compared with. Pin what can be pinned (seed, clock, time zone, ordering, concurrency level) one at a time: the variable whose pinning makes the rate zero is the cause or next to it. A fix that lowers the rate has not fixed it; the loop must go to zero over a run at least ten times longer than it took to see the first failure.

## Production-only failures

List what differs: data, configuration, versions, load, clock, the client. Reproduce the data first (the real record, scrubbed of personal data), then the configuration. Add read-only logging in production only for the one value a hypothesis needs, tagged and redacted, and remove it in the same change as the fix.

## Environments that will not run

Missing service, credentials or dataset: about 10 minutes of trying the obvious (a local container, a test mode, a recorded response), then report what is needed and from whom. Do not read code to guess in its place.

## No seam

If the bug cannot be reached by any test without rewriting the module (logic buried in a handler, global state, time read inline), the failing command is a script that calls the code as it is, and the report says the module has no seam and where one would go.
