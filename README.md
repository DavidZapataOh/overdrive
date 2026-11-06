# Overdrive

Overdrive is a Claude Code plugin that scales the amount of process to the risk of each change. A deterministic classifier assigns every task to one of three lanes: `direct` for trivial edits, `standard` for ordinary work and `critical` for changes that touch data, auth, money, secrets or public contracts. Each lane brings only the planning, review and evidence it needs, so small changes stay fast and risky ones are never merged under-reviewed.

## Install

Installation is the same on macOS, Linux and Windows, through Claude Code's plugin commands. The repository is private for now, so authenticate with GitHub first:

```sh
gh auth login && gh auth setup-git
export CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1
claude plugin marketplace add DavidZapataOh/overdrive
claude plugin install overdrive@overdrive
```

## Development

Run the shell tests with `bash tests/run.sh [FILTER]`, where `FILTER` is an extended regular expression matched against test file paths. Contributor rules are in `.claude/CLAUDE.md`.
