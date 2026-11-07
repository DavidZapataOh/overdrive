# Descriptions

The description is the only text Claude sees before it decides to load a model-invoked skill, and it is listed in every session, so each character costs context in every turn. A user-invoked skill (`disable-model-invocation: true`) is not listed; its description only labels it in the `/` menu.

## Rules

1. **Situations, never steps.** Name what the user is doing or asking for. When a description summarizes the workflow, Claude follows the summary and skips the body. No "first", "then", "step", numbered phases or rules in it.
2. **Capability first, as a short noun phrase,** then the situations: "Commit message style for this repository. Use when committing, writing or rewording a commit message, even when the user asks for a one-word message."
3. **Third person.** Not "I can help you", not "You should".
4. **Key use first.** Claude Code truncates the listing (description plus `when_to_use`) at 1,536 characters, and a crowded listing drops descriptions entirely.
5. **Length.** At most 1,024 characters for any skill; a model-invoked skill in a plugin with many skills belongs well under 300.
6. **Near-miss boundaries.** When a neighboring need shares the keywords, say what the skill is not for, or make it user-invoked: "Not for release notes or PR descriptions."
7. **Words people type.** Include the terms, symptoms, error text and file types a user would actually write, including the non-obvious ones ("even if they don't say commit").
8. **No `<` or `>`.** They render as entities; use `[skill-name]` or `argument-hint`.

## Examples

Bad, workflow summary:

```yaml
description: Writes a failing test first, then the minimum code, then refactors.
```

Good, situations:

```yaml
description: Test-driven changes in this codebase. Use when implementing a feature or fixing a bug, before writing implementation code, including one-line fixes.
```

Bad, too vague to trigger and too broad to stay out of the way:

```yaml
description: Helps with git.
```

Good, with a boundary:

```yaml
description: Commit message style for this repository. Use when committing, writing, squashing or rewording a commit message. Not for release notes, changelogs or PR descriptions.
```

## Tuning against the trigger set

Change the description only to fix a failing **train** case, never by pasting the words of a failing case into it. Rerun the full trigger set each round, keep the round with the best **validation** accuracy (it may not be the last), and stop after five rounds. If validation will not reach 90 %, the boundary is wrong: split the skill, narrow it, or make it user-invoked.
