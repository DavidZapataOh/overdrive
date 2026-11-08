# Non-regression check

For the critical lane, before the green evidence. Two facts to establish: the new tests fail on the previous code, and the old suite still passes on the new code.

Start with the implementation in the working tree, uncommitted, and the tests committed and pinned. `<impl paths>` are the files you changed to implement, `<base>` is the commit before the tests.

1. **New tests are red on the previous code.** Put the implementation aside, run the new tests, restore it:

   ```bash
   git stash push -u -- <impl paths>
   <test command for the new test files>      # must fail
   git stash pop
   ```

   `-u` matters: a new implementation file is untracked, and without it the stash leaves that file in place, so the new tests pass "on the previous code" and prove nothing. Run this in its own command, before the green evidence, so the order shows in the record.

   Where a stash is not possible (the implementation is already committed), use a worktree at the tests commit:

   ```bash
   git worktree add ../check-prev <tests commit>
   (cd ../check-prev && <test command for the new test files>)     # must fail
   git worktree remove ../check-prev
   ```

2. **The old suite is green on the new code.** No test that existed at `<base>` was changed, skipped or deleted:

   ```bash
   git diff --name-status <base> -- <test paths>     # only A (added) lines
   ```

   then the full suite passes with `${CLAUDE_PLUGIN_ROOT}/bin/overdrive evidence green -- <full test command>`.

A new test that passes on the previous code did not need the change; rewrite it before moving on. A modified or deleted old test needs a stated reason in the final message.
