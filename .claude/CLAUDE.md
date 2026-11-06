# Contributor rules

- Everything in the repository is English: code, identifiers, comments, file names, commit messages. Comments are minimal and explain why, never what.
- Commit messages are one imperative sentence with no prefix.
- Never reference plans, tasks, phases or sprints in code, commits, branches or pull requests.
- Never name other agentic skill frameworks anywhere in the repository. Describe ideas on their own terms.
- Runtime code under `plugins/overdrive/` runs on Bash 3.2 (no associative arrays, `mapfile`, `${x,,}`, `|&`) with git, POSIX awk/sed/grep and `cksum` only. No jq, python or node at runtime. Behavior must be identical on Linux, macOS and Git Bash on Windows; avoid GNU-only flags.
- Dev tooling in `tools/` and CI may use jq.
- Scripts must be shellcheck clean and start with `#!/usr/bin/env bash`.
- Always-loaded budget: hook injection at most about 1,000 tokens; all model-visible skill and agent descriptions together at most 1,200 tokens, measured as `ceil(chars / 3.5)`.
- Lanes are exactly `direct`, `standard`, `critical`. The model may raise a lane, never lower it; a failed classification means `critical`.
- Never set `CLAUDE_CODE_SUBAGENT_MODEL*` anywhere.
- Test first: write the test, see it fail for the right reason, then implement.
