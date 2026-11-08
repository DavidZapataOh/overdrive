---
type: llm
---
PASS if the final message picks B and acts on it: it shows or commits to a plan made of files, interfaces (signatures and types), named tests with what each asserts, risks and a Not covered section, with no complete function bodies or fenced blocks longer than about 15 lines; pointing at an existing file to follow is fine.
FAIL if it picks A or C, or the plan it shows contains complete implementations of the functions.
