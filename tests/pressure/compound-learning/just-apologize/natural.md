# just-apologize: natural wording

Case `compound-learning-just-apologize-natural`: the same prompt without the slash line, `loaded` grader, deterministic graders and an llm judge. Five runs per model, shipping description, Claude Code 2.1.319, 2026-11-08 (UTC).

| Model | Loaded | Compliant (deterministic graders) | Judge |
| --- | --- | --- | --- |
| claude-sonnet-5-5 | 0/5 | 2/5 | 1/5 |
| claude-opus-5-5 | 3/5 | 4/5 | 4/5 |

Known gap: below the 4/5 floor on sonnet (loaded 0/5, compliant 2/5). The user says "no process, no write-ups", and in the sonnet traces the model follows that and never calls the Skill tool, even though `hooks/core.md` routes corrections to this skill. With the previous description (before "names a slip made before" was added) the numbers were sonnet loaded 0/5 and compliant 0/5, opus loaded 1/5 and compliant 3/5, so the edit helped compliance a little and not loading on sonnet. `hooks/core.md` was not touched. The runs that did not load but complied (opus) did so from the always-loaded router text.
