# Forms of a learning

## Contents

- Choosing the form
- Automatic check
- Proving a check
- Rule
- Note
- Where it lives

## Choosing the form

Take the first form that can hold this learning, in this order:

| Form | Fits when | What it costs the next session |
| --- | --- | --- |
| Automatic check | the mistake can be recognized in files or output: a pattern in the code, a missing argument, a forbidden command, a path, a lane | nothing: it fails by itself |
| Rule | the mistake is a judgment no program can see (tone, naming, which tool to prefer) | a line the next session must read |
| Note | the mistake depends on a situation that only matters when working in one area | a lookup the next session must make |

A check beats a rule because a rule is exactly what was just broken: when CLAUDE.md already says it and the agent broke it anyway, a second line saying it louder, in capitals or in bold changes nothing. Go up the ladder, not sideways.

## Automatic check

Use the project's own test runner and conventions so the check runs where the tests already run.

| Mistake | Check |
| --- | --- |
| a leftover pattern in source (`console.log`, `debugger`, a Spanish comment, a call without a required argument) | a test that reads the files under the source directory and fails on the pattern, naming file and line |
| a forbidden command or file (`npm` in a pnpm repo, a lockfile of the wrong manager) | a `preinstall` script or a test that fails on it |
| a lane that was too low | a risk-map rule: [calibrate-risk-map.md](calibrate-risk-map.md) |
| a wrong value reaching users | a regression test through the public interface |
| something only a hook can stop (a command before it runs) | a hook, only when the project already uses hooks |

Scope the check to what was wrong. A check that flags user-facing strings when the mistake was comments, or flags every `console` call when the mistake was `console.log`, gets disabled the first time it is wrong. Fix every existing instance first, so the check passes on the tree.

## Proving a check

A check counts only after both of these have run, in this order:

1. It passes on the tree: run the project's test command; it exits 0.
2. It fails on a throwaway copy that has the defect: copy the tree outside the repository, put the defect in the copy and run the same check there.

```
copy=$(mktemp -d) && cp -R . "$copy/tree" && cd "$copy/tree"
printf '%s\n' '<the defect line>' >> <a file the check covers>
<the project's test command>      # must exit non-zero and name the defect
```

Delete the copy afterwards. Never put the defect into the real tree, not even to revert it. A check that cannot be made to fail is not a check: take the next form and say why.

## Rule

One line, positive and observable ("Comments are English; Spanish only in strings shown to users"), added to the CLAUDE.md that governs the files concerned. A decision about scope or priority goes in the decision log instead: read `${CLAUDE_PLUGIN_ROOT}/skills/decision-log/SKILL.md` and follow it.

## Note

`.overdrive/learnings/<slug>.md`, committed with the code, read back only through `overdrive recall <terms>`:

```
---
title: <what to do, in a few words>
date: YYYY-MM-DD
applies_when: <the situation in which this matters, in words someone would search for>
area: <module, domain or tool>
---
<What went wrong and what to do instead, two to five lines. Name the file or command, and what proves it.>
```

`applies_when` and the body are what `recall` matches, so write the words a later task would contain. One learning per file.

## Where it lives

- A principle the user states for everything ("always answer me in Spanish", "never mock the database") goes to the user-level memory index or user-level CLAUDE.md, not into the repository and not narrowed to this project.
- A rule about this project goes in this project's CLAUDE.md, decision log or `.overdrive/`.
- Personal preferences are never copied into a repository that other people read.
