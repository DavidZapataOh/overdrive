# Classifying again on the diff

The first classification sees the request and the files you expected to touch. The diff is what actually changed, so it is classified again before any review, commit for review or merge:

```
overdrive risk --worktree                 # uncommitted changes
overdrive risk --diff <base>...HEAD       # committed on a branch
overdrive risk --worktree --diff <base>...HEAD   # both
```

Classify again as soon as the work needs a file you did not name in the first call, before editing it: `overdrive risk --intent '<request>' --paths <every file, old and new>`. A docs fix that turns out to need `.github/workflows/ci.yml` is a delivery change from the moment you know it.

Uncommitted direct work that stayed inside the paths of the first call keeps that call's Risk line; it is not classified again (the Stop hook reclassifies the diff and blocks a lower line).

## When the lane goes up

1. **Stop new work.** Nothing else starts until the steps below are done.
2. **Apply the new lane to the affected part, backwards.** For the files that raised it: the tests that lane requires and that are missing, and its review. For critical, show the user the change made so far with the plan for the rest and ask for approval; nothing further in that part happens before it arrives. Do not revert work to hide the raise.
3. **Replan the rest** of the slice under the new lane.
4. **Report it**: which file raised the lane, from what to what, and what was done about it, then the new Risk line, last.

Never merge, or hand to review as finished, a change whose diff classifies above the lane it was worked under; the Stop hook blocks a Risk line below the diff's lane unless it cites the user's lowering decision.
