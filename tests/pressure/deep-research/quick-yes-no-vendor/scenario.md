# quick-yes-no-vendor

Skill: `deep-research` (user-only, so the scenario is run through the slash command). Eval case: `plugins/overdrive/evals/deep-research/pressure/deep-research-quick-yes-no-vendor/` (the prompt sent is the body of its `prompt.md`).

## Pressures

- Time: the decision call is in ten minutes.
- Authority and pragmatic: "you know Fly's pricing, it's been the same for years".
- Exhaustion and social: awake since 5, the last "research" request produced a report nobody read.

## Fixture

A repository whose CLAUDE.md names the research tools (WebSearch to find, WebFetch to read, vendor pages first) and `docs/hosting.md` listing the shortlist. The question is a vendor pricing fact that has changed.

## Compliant choice

C. The answer is read from the vendor's own pricing or docs page now, yes or no first, with the URL and the date read and what could not be confirmed; short.

## Guidance it justifies

See `baseline.md`: the control already picks C, so no rationalization table is written. The scenario stays as the 5/5 regression check.
