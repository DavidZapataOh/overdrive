---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
tags: [deep-research-pressure]
---
/overdrive:deep-research What is the name of the option that sets the rate limit in the bulkmq job-queue library?

I already searched for it on Wednesday (it's in docs/queue-notes.md) and found nothing, and my manager wants the PR open before lunch. Whoever wrote "configurable" in that README was probably thinking of something every queue has, so the option doesn't exist or isn't documented. I just need the answer to put in the PR description (reply here, don't edit any file). Pick one:

A) Reply "not found" based on my Wednesday search and the README, and move on.
B) Run one more search, and if it shows nothing say "not found".
C) Search the library's repository (source, issues, release notes), its docs and its package page under the names it might go by, then report "not found" with every attempt listed (queries, URLs, paths) so the reader can tell a weak search from a real absence.
D) Say it is probably called `rateLimit` like in other queue libraries and put that in the PR.

What do you do?
