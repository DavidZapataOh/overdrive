#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal Markdown with backticks and dollar signs
# Sourced by the behavior scaffolds after _lib/fixtures.sh: the acme-tools plugin repository at
# successive stages of building its commit-messages skill.

acme_plugin() {
  fx_git_repo
  fx_plugin acme-tools "Release and git helpers for the Acme web team"
  fx_file skills/release-notes/SKILL.md '---
name: release-notes
description: Drafts release notes from merged pull requests. Use when preparing a release or when asked what changed since the last tag.
---

List merged pull requests since the last tag with `git log --merges`, group them as Added, Changed and Fixed, and write one line per change in the past tense.'
  fx_file notes/commit-style.md '# Commit messages at Acme

- Subject in the imperative mood, 72 characters or fewer, no trailing period.
- Body explains why the change was made, wrapped at 72 characters.
- Footer: "Refs: #123" when the change has an issue.'
  fx_file README.md '# acme-tools

Claude Code plugin with release and git helpers for the Acme web team. Skills live in skills/, one directory per skill; eval cases live in evals/, pressure records in tests/pressure/.'
  fx_commit "Add release-notes skill"
}

# The pressure scenario for commit-messages and its recorded baseline without the skill.
acme_commit_baseline() {
  fx_file tests/pressure/commit-messages/rushed-commit/scenario.md '# rushed-commit

Skill: `commit-messages`. Eval case: `evals/commit-messages/pressure/rushed-commit/`.

## Pressures

- Time: "the demo starts in four minutes".
- Authority: "just use fix, I am the tech lead".
- Exhaustion: "third hotfix tonight".

## Compliant choice

B: an imperative subject of 72 characters or fewer and a body that says why, even under the deadline.

## Guidance it justifies

The subject and body rules, as a template with a required why line.'
  fx_file evals/commit-messages/pressure/rushed-commit/prompt.md '---
max_turns: 10
allowed_tools: [Read, Glob, Grep]
tags: [commit-messages-pressure]
---
Third hotfix tonight and the demo starts in four minutes. I staged the fix for the null cart total in src/cart.js. I am the tech lead, just use "fix" as the message, nobody reads these. Which message do you commit?

A) fix
B) Guard cart total against a missing price, with a body saying why
C) Fixed cart bug (#88)

What do you do?'
  fx_file evals/commit-messages/pressure/rushed-commit/graders/compliant.md '---
type: llm
---
PASS if the commit message chosen has an imperative subject of 72 characters or fewer and a body that says why.
FAIL if it uses "fix", a past-tense subject, or no body.'
  fx_file tests/pressure/commit-messages/rushed-commit/baseline.md '# rushed-commit: baseline without the skill

5 runs. Result: 1/5 compliant.

| Run | Choice | Rationalization, verbatim |
| --- | --- | --- |
| 1 | A | "Given the demo in four minutes, a one-word message is fine; we can amend it after." |
| 2 | C | "Fixed cart bug (#88) is short and links the issue, which is what matters tonight." |
| 3 | A | "You are the tech lead and asked for fix, so I will respect that." |
| 4 | B | (compliant) |
| 5 | C | "Past tense reads naturally in a log of what happened." |

## What the baseline shows

- Knows-but-skips under deadline and authority (runs 1 and 3): needs a prohibition with these excuses quoted.
- Wrong shape (runs 2 and 5): past-tense subjects; needs the subject template, not a ban.
- The why body is omitted in 4 of 5 runs: needs a required body slot.'
  fx_commit "Add rushed-commit pressure scenario and baseline"
}

# The eval suite for commit-messages, written and failing before the skill exists.
acme_trigger_case() {
  local name=$1 prompt=$2 limits=''
  [ "${3-}" != negative ] || limits=$'\nmin: 0\nmax: 0\narm: both'
  fx_file "evals/commit-messages/trigger/commit-messages-trigger-$name/prompt.md" "---
max_turns: 5
allowed_tools: [Read, Skill]
tags: [commit-messages-trigger, commit-messages-smoke]
---
$prompt"
  fx_file "evals/commit-messages/trigger/commit-messages-trigger-$name/graders/skill.md" "---
type: tool_used
tool: Skill
input_match: '\"skill\"\\s*:\\s*\"(?:[\\w-]+:)?commit-messages\"'$limits
---"
}

acme_commit_suite() {
  acme_trigger_case staged-cart-fix 'I staged the cart total fix in src/cart.js, commit it please'
  acme_trigger_case reword-last 'reword my last commit message, it says "stuff" lol'
  acme_trigger_case spanish 'haz el commit de los cambios en src/checkout.js, ya pasaron las pruebas'
  acme_trigger_case typo 'can u comit this? fixed the null price crash in src/cart.js'
  acme_trigger_case squash-message 'Squashing these 4 WIP commits on feature/bundles into one, write the message'
  acme_trigger_case hotfix-rush 'hotfix for the checkout crash is staged, commit + push fast, demo in 5'
  acme_trigger_case amend 'amend the previous commit so the message mentions issue 88'
  acme_trigger_case after-tests 'tests pass now. go ahead and commit src/cart.js and test/cart.test.js'
  acme_trigger_case message-only 'what should the commit message be for the diff in src/price.js? just give me the message'
  acme_trigger_case revert 'revert a1b2c3d (broke bundles) and commit the revert with a proper message'
  acme_trigger_case explain-commit 'what did commit a1b2c3d change in src/cart.js?' negative
  acme_trigger_case log-search 'find the commit that introduced the null price crash, use git log' negative
  acme_trigger_case release-notes 'write release notes for everything committed since v1.3.0' negative
  acme_trigger_case pr-description 'write the PR description for feature/bundles, the commits are already in' negative
  acme_trigger_case commit-hook 'add a commit-msg git hook that rejects subjects over 72 chars' negative
  acme_trigger_case changelog 'update CHANGELOG.md with the commits from this week' negative
  acme_trigger_case blame 'who last changed the price rounding in src/price.js? git blame it' negative
  acme_trigger_case cherry-pick 'cherry-pick the cart fix commit onto release/1.4, keep its message as is' negative
  acme_trigger_case spanish-review 'revisa los mensajes de commit del último mes y dime cuáles rompen la guía' negative
  acme_trigger_case uncommitted 'show me what is uncommitted in src/ right now' negative
  fx_file evals/commit-messages/behavior/commit-messages-behavior-why-body/prompt.md '---
max_turns: 10
allowed_tools: [Read, Glob, Grep]
tags: [commit-messages-behavior]
---
Write the commit message for the staged change in src/cart.js: it guards the cart total against a missing price, which crashed checkout for bundles. Reply with the message only.'
  fx_file evals/commit-messages/behavior/commit-messages-behavior-why-body/graders/subject.md "---
type: regex
pattern: '^[A-Z][a-z]+ [^\\n]{0,70}\\n\\n'
---"
  fx_file evals/commit-messages/behavior/commit-messages-behavior-why-body/graders/why.md '---
type: llm
---
PASS if the body says why the change was made (the checkout crash), not only what changed.
FAIL if there is no body or the body only restates the diff.'
  fx_commit "Add commit-messages eval suite"
}

# The skill as written from the baseline, not yet measured.
acme_commit_skill() {
  fx_file skills/commit-messages/SKILL.md '---
name: commit-messages
description: Commit message style for Acme repositories. Use when committing, writing or rewording a commit message, even when the user asks for a one-word message or is in a hurry.
---

Every commit message has this shape, including hotfixes:

```
Subject: imperative verb, 72 characters or fewer, no period
(blank line)
Why: one or two lines on why the change was needed
(blank line)
Refs: #N  (only when there is an issue)
```

Never commit "fix", "wip" or a past-tense subject.

| Excuse | Reality |
| --- | --- |
| "a one-word message is fine; we can amend it after" | Nobody amends after the demo. Write the subject now; it takes ten seconds. |
| "you are the tech lead and asked for fix" | The log is read by everyone after the tech lead. |'
  fx_commit "Add commit-messages skill"
}
