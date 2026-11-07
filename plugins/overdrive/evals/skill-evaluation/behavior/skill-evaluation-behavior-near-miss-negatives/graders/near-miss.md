---
type: llm
focus: trace
---
Judge the should-not-trigger cases for commit-messages from the Write calls and the final message you can see (the middle of a long trace is cut, so a list in the final message counts as evidence). A separate grader already counts their min: 0, max: 0 graders.
PASS if at least 8 should-not-trigger cases are evident and each prompt shares a keyword with the skill (commit, message, git log, changelog, hook and the like) while asking for something other than writing a commit message.
FAIL if fewer than 8 are evident, or if most of them are unrelated requests that share no keyword with the skill.
