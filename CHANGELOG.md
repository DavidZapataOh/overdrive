# Changelog

## Unreleased

- Critical lane: the PreToolUse guard denies dispatching `overdrive:final-reviewer` and `gh pr create` / `gh pr merge`, and `overdrive review-package --require-green` refuses, while a task the ledger marks critical (`Task N: in-progress critical`) has no `reviewing` line after its last change. A ledger binds to the run's branch (at `ledger init` on a non-default branch, else at the first `ledger add` made on one) and gates only there; a critical task stays gated after `complete` until a review follows its last change. `overdrive brief` marks a critical task in the ledger itself, `Run: closed — <reason>` releases an abandoned run, and `overdrive ledger unreviewed [--all-started] [--any-branch]` lists the tasks.
- `risk-triage`: classifies every repository change before its first edit and again on the diff, raises lanes the classifier cannot see, lets only the user lower a floor after hearing the risk (recorded as a decision), and proposes a project risk map once. The session router names the CLI by its absolute path and loads this skill for every change.
- Briefs and review packages carry an `Overdrive CLI:` line with the CLI's absolute path for agents.
- `overdrive risk` works when `TMPDIR` is not writable, falling back to `/tmp` and then the repository's run directory.
- The Stop hook asks for a Risk line only when the turn actually changed a repository.
- Marketplace and plugin manifests.
- `skill-evaluation`: user-invoked workflow for writing a skill test first (pressure baseline, eval suite, skill, pressure again, measurement), with `new-pressure-case` and `split-trigger-set` scripts.
- `deep-research`: user-invoked research workflow that splits a question across `overdrive:researcher` agents with neutral briefs, caps each researcher, labels patterns, gaps and bets, and writes a sourced report file.
- `overdrive brief --text TEXT --neutral [--rules TEXT|-] [--cap N] [--stdout]`: a research brief with the task, rules, cap and report contract only, written under `${TMPDIR:-/tmp}/overdrive-briefs/` or printed with `--stdout`; `deep-research` uses it for comparisons.
- Reviewer agents write findings to the file the prompt or brief names, defaulting to the review package stem.
