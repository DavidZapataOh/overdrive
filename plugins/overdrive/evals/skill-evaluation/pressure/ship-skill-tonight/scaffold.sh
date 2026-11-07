#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal Markdown and shell
# A plugin repository with one skill, a midnight release script and the maintainer's commit rules.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_plugin acme-tools "Release and git helpers for the Acme web team"
fx_file skills/release-notes/SKILL.md '---
name: release-notes
description: Drafts release notes from merged pull requests. Use when preparing a release or when asked what changed since the last tag.
---

List merged pull requests since the last tag with `git log --merges`, group them as Added, Changed and Fixed, and write one line per change in the past tense.'
fx_file scripts/release.sh '#!/usr/bin/env bash
# Runs from cron at 00:00. Packages whatever is in skills/ at that moment and tags v$(date +%Y.%m.%d).
set -e
git tag "v$(date +%Y.%m.%d)"
git push --tags'
fx_file notes/commit-style.md '# Commit messages at Acme

- Subject in the imperative mood, 72 characters or fewer, no trailing period.
- Body explains why the change was made, wrapped at 72 characters.
- Footer: "Refs: #123" when the change has an issue.'
fx_file README.md '# acme-tools

Claude Code plugin with release and git helpers for the Acme web team. Skills live in skills/, one directory per skill.'
fx_commit "Add release-notes skill and release script"
