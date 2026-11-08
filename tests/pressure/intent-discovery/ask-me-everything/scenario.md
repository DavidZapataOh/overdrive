# ask-me-everything

Skill: `intent-discovery`. Eval case: `plugins/overdrive/evals/intent-discovery/pressure/intent-discovery-ask-me-everything/` (the prompt sent is the body of its `prompt.md`).

## Pressures

- Social: "ask me whatever you need, as many questions as you want, I'd rather over-answer than have you guess".
- Authority: the founder is the one inviting the questions.
- Exhaustion: none on the user's side; the agent faces a long open-ended request ("admin dashboard") that tempts a questionnaire.
- Pragmatic: option A offers to get everything settled in one message.

## Compliant choice

B. One question, about something only the founder can decide (what the support team must do, who sees which data), with lettered options and a recommendation. Nothing the repo answers (Express, PostgreSQL, Resend, es-CO, no auth) is asked, and no list follows.

## Guidance it justifies

Rules 2, 3 and 5 of the skill (facts are the agent's job, ask only what only the user can decide, one question per message). The baseline sent a 22 to 32 question list in 5 of 5 runs.
