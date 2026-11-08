# Merge and deploy check

## Contents

- Merge method
- Merging
- After the merge

## Merge method

Follow the repository's own history. Count how the last 20 first-parent commits on the default branch were made:

```bash
git log --first-parent -20 --format=%p BASE | awk 'NF > 1 { m++ } END { print (m * 2 > NR) ? "--merge" : "--squash" }'
```

A commit with two parents is a merge commit. More than half merge commits prints `--merge`; otherwise, and with no history, `--squash`. Never `--rebase` unless the history is linear and the person asked.

## Merging

Preconditions, all observable: `auto-merge on` in `.overdrive/project.conf`; the review for this head is on record (SKILL.md rule 5); for a critical pull request, that is the only path.

1. Prefer GitHub's own auto-merge, which waits for CI without anyone watching: `gh pr merge <number> --auto <method> --match-head-commit <head sha>`. It needs required status checks on the default branch; if `gh` says auto-merge is not available there, use step 2.
2. Otherwise start the one background watcher (SKILL.md rule 7). When it exits 0: `gh pr merge <number> <method> --match-head-commit <head sha>`. When it exits non-zero, take the failing check names from `gh pr checks <number>` once, fix on the same branch with a new commit (never force-push), push, and start one new watcher. A failing check is never merged over.
3. `--delete-branch` only for branches this session created.

`--match-head-commit` makes the merge fail if the branch moved after the diff was classified and reviewed.

## After the merge

Skip this when the repository has no deploy: no workflow that mentions deploy or release, and no smoke URL in the README or `.overdrive/project.conf`. Say that it has none.

Otherwise find the deploy for the merge commit and watch it once in the background:

```bash
gh run list --commit <merge sha> --json databaseId,name,status --limit 5
gh run watch <databaseId> --exit-status    # run_in_background
```

Then hit the smoke URL when there is one (`curl -fsS -o /dev/null -w '%{http_code}' <url>`) and report: the merge commit, the run URL and conclusion, and the status code. A deploy that fails is reported as failed with its run URL; do not revert or push anything without being asked.
