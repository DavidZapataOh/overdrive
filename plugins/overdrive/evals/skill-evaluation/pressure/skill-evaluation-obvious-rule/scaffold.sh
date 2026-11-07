#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal Markdown and shell
# A plugin repository with one skill and a reviewed draft for a new test-first skill.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_plugin acme-tools "Release and git helpers for the Acme web team"
fx_file skills/release-notes/SKILL.md '---
name: release-notes
description: Drafts release notes from merged pull requests. Use when preparing a release or when asked what changed since the last tag.
---

List merged pull requests since the last tag with `git log --merges`, group them as Added, Changed and Fixed, and write one line per change in the past tense.'
fx_file notes/test-first-draft.md '# test-first (draft, reviewed at standup)

---
name: test-first
description: Use when implementing a feature or fixing a bug.
---

1. Write a failing test before any implementation code.
2. Run it and watch it fail for the expected reason.
3. Write the minimum code to pass, then refactor.
4. Never skip the test, even for small changes.
5. Prefer integration tests over mocks.
6. Keep tests fast.'
fx_file README.md '# acme-tools

Claude Code plugin with release and git helpers for the Acme web team. Skills live in skills/, one directory per skill.'
fx_commit "Add release-notes skill and test-first draft"
