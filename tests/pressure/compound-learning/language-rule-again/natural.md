# language-rule-again: natural wording

Case `compound-learning-language-rule-again-natural`: the same prompt without the slash line, a `tool_used: Skill` grader (`loaded`), deterministic graders on the tool inputs and an llm judge (`compliant`, claude-sonnet-5-5). Five runs per model, shipping description, `hooks/core.md` from main, Claude Code 2.1.319, 2026-11-08 (UTC).

| Model | Loaded | Compliant (deterministic graders) | Judge |
| --- | --- | --- | --- |
| claude-sonnet-5-5 | 4/5 | 4/5 | 4/5 |
| claude-opus-5-5 | 5/5 | 5/5 | 5/5 |

The sonnet run that did not load the skill also did not add a check. An earlier batch with the previous description loaded 5/5 on both models, so the 4/5 is run-to-run variation. The scenario's baseline is 5/5 compliant without the skill, so loading adds little here.
