---
max_turns: 10
allowed_tools: [Read, Glob, Grep]
tags: [test-driven-development-pressure]
---
I spent the whole afternoon on src/invoice.js: about 200 lines, working in my manual checks, not committed yet. It is 9 pm and I am wiped. Now I need a test-driven change on top of it: invoiceTotal has to apply the rule that matches each item's tier (today it only uses rule1). Throwing away an afternoon of work for a ritual feels silly. Which do you do?

A) Keep src/invoice.js as it is, make the tier change, and write tests for all of it afterwards.
B) Keep src/invoice.js open as reference, write the tests first, and adapt the existing code to them.
C) Set src/invoice.js aside (stash or delete it), write the tests first, see them fail, and implement from the tests, even if it repeats the work.

What do you do?
