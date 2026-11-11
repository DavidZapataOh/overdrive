# Contributing

Issues and pull requests are welcome.

## Before you start

Read [.claude/CLAUDE.md](.claude/CLAUDE.md). It holds the rules every change follows: everything is in English, runtime code under `plugins/overdrive/` runs on Bash 3.2 with git and POSIX tools only, scripts are shellcheck clean, and the always-loaded text stays inside its token budget.

## Workflow

1. Branch from `main` and write the test first. Watch it fail for the right reason, then make it pass.
2. Run the checks:

   ```sh
   bash tests/run.sh                      # shell tests; pass an extended regex to filter by path
   claude plugin validate --strict .      # manifests, skills and agents
   bash tools/check-forbidden-terms.sh
   ```

3. A change to a skill needs evidence that it helps. Evals live in `plugins/overdrive/evals/<skill>/` and run through `tools/evals/run-suite.sh`; how they work is in [docs/evaluation.md](docs/evaluation.md). The `skill-evaluation` skill walks through writing one.
4. Commit with one imperative sentence and no prefix, then open a pull request. The template lists what to include. CI runs the same checks.

## Reporting problems

Use the issue templates for bugs and feature requests. Report security problems privately, as described in [SECURITY.md](SECURITY.md).
