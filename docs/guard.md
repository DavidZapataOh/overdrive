# Tool-call guard

Overdrive registers a `PreToolUse` hook on `Edit`, `Write`, `MultiEdit`, `NotebookEdit`, `Bash`, `Agent`, `Task` and `Read`. It enforces the rules that must hold on every call: pinned tests stay untouched until green, the default branch is never pushed to, and a critical-lane run does not reach its final review or its pull request while a task lacks a review. Everything else is left to the skills and the review.

## What it does

It denies only what it recognizes: edits through the file tools, the shell forms and the agent dispatches listed below. Anything else that changes a pinned test is caught later by the green evidence check (see Known gaps).

| Call | Result |
| --- | --- |
| `Edit`, `Write`, `MultiEdit` or `NotebookEdit` on a pinned test (listed in `.overdrive/run/pins` of the file's repository) | denied: `<path> is a pinned test. Tests change only before the red run. If the test itself is wrong, run: overdrive pin --release "<reason>" and redo red.` |
| A file tool on `.overdrive/run/pins` while it exists | denied |
| Any file-tool edit, or recognized shell write, in a repository whose pins file cannot be read, does not parse or fails its seal | denied until `overdrive pin --release "<reason>"` |
| A shell command whose recognized write reaches a pinned test: redirections (`>`, `>>`, `>\|`, `&>`), `tee`, `sed -i`, `perl -i`, `rm`, `mv`, `cp`, `ln`, `install`, `truncate`, `dd of=`, `unlink`, `shred`, `sort -o`/`--output`, `awk`/`gawk -i inplace`, `uniq IN OUT`, `git checkout`, `git restore`, `git rm`, `git mv` | denied; a directory or glob that covers a pinned test counts, including the repository itself, a folder above it and `/` |
| `git switch`, or `git checkout` of a branch or commit (any operand that is not an existing path, or `-b`, `-B`, `--orphan`, `--detach`), in a repository with pins | denied: finish green and `overdrive pin --clear`, or release |
| `git push` that would update the default branch: an explicit refspec (`main`, `+main`, `HEAD:main`, `heads/main`, `refs/heads/main`, a wildcard), a push with no refspec while `HEAD` is on it, `--all`, `--mirror`, `--delete` of it | denied, with or without `--force` |
| A file tool on a ledger file (`.overdrive/run/active-ledger`, `.overdrive/run/*/ledger.md`) | denied: the ledger is written only by `overdrive ledger add`, because the guard writes the review and change records itself and a file tool would forge them |
| A shell command that runs the ledger's internal `_record-review` or `_record-change` entry points (a mention inside a quoted string is only text) | denied |
| Dispatching `overdrive:final-reviewer` while the active ledger holds a started task that is marked critical and has no critical review after its last change, or an unmarked started task that is neither `complete` nor `blocked` | denied, naming the tasks and the `review-package` and `overdrive:critical-reviewer` steps that clear them |
| `gh pr create` or `gh pr merge` while the active ledger holds a critical task with no critical review after its last change | denied with the same text; `gh pr merge` also checks ledgers bound to other branches, because a merge can run from the default branch |
| Dispatching `overdrive:critical-reviewer` with `Task N` in its description (or `Tasks 1-2`, or a `task-N.md` brief path in the prompt) | allowed; the guard appends `Task N: reviewed by critical-reviewer` to the active ledger |
| Dispatching `overdrive:builder` with `Task N` in its description | allowed; the guard appends `Task N: changed by builder`, which makes the task need a new review |
| A file tool call, or a shell command outside a small read-only allowlist, that goes ahead | writes `.overdrive/run/markers/<session_id>.changed` in every repository it runs in, once: the commit the change starts from and a checksum of the branches, tags and stash; a file tool also leaves `<session_id>.edited`. Paths inside the plugin's own directory and writes under `.overdrive/run/` are not marked |
| The plugin's own read-only commands, run by the CLI's absolute path: `overdrive risk`, `overdrive decisions next-id`, `overdrive decisions check`, `overdrive recall`, with only plain words and quoted strings after them (no `;`, `&`, `\|`, redirection, `$`, backquote, glob or `~` outside quotes) | allowed without a permission prompt (`permissionDecision: allow`); deny and ask rules in the user's settings still apply. A quoting is used only when the root can be written that way as one literal word: a root with a single quote is never written in single quotes, one with a double quote, `$`, a backquote or a backslash never in double quotes, and unquoted needs a plain path |
| The same commands run through the router's root variable: one assignment of a variable named `R` or ending in `ROOT` (`OD_ROOT`, `PLUGIN_ROOT`) to the plugin's root (`R=<root>;` or `&&`, quoted or not), then `$R/bin/overdrive`, `"$R"/bin/overdrive` or `"${R}/bin/overdrive"` with the same arguments | allowed; a different value, a second assignment or any other variable name (`IFS`, `PATH`, `TMPDIR`) is not |
| `Read` of a file inside the plugin's directory | allowed (`permissionDecision: allow`); the path is normalized first, then it must exist and be a regular file or directory that resolves, through every symbolic link, inside the directory; anything else gets no decision |

The shell reader follows quotes, escapes, comments, line continuations, here-documents, `cd`, `pushd`/`popd`, subshells and `$(...)` (a `cd` inside them ends with them), `git -C`, the wrappers `sudo`, `env`, `nice`, `timeout`, `stdbuf`, `nohup`, `command`, `builtin`, `exec`, `time`, `xargs` and `ionice`, and the strings run by `sh -c`, `bash -c` and `eval`.

The repository is found from the file's own path, or from the call's `cwd` and each directory the command moves to, never from the session's project directory: a session that starts above the repository still finds it, and a call outside any repository is a no-op. The default branch is the one `refs/remotes/<remote>/HEAD` points at; without it, both `main` and `master` are protected. Linked worktrees are followed through their `.git` file. On macOS and Windows, paths compare without case.

## Critical-lane gate

The gate reads the ledger that `overdrive ledger init` made active (see [lanes.md](lanes.md) for the whole flow). A task counts as unreviewed when the ledger marks it critical (`Task N: in-progress critical`, written by `overdrive brief` for a critical task) and holds no `reviewed by critical-reviewer` line after its last `in-progress`, `implemented`, `fixing round` or `changed by builder` line. A task stays listed after `complete` until a review follows its last change. `overdrive ledger unreviewed [--all-started] [--any-branch]` prints the same list, and `overdrive review-package --require-green` applies it to a critical package and exits 65 while it is not empty.

A ledger binds to the run's branch (at `ledger init` on a non-default branch, otherwise at the first `ledger add` made on one) and gates only there. `Run: closed — <reason>` frees other branches; on the run's own branch the gate stays.

The review is recorded by the dispatch, not by the verdict: the guard does not read the reviewer's findings. Acting on them is the fix loop's job; the review package and the final review check the evidence.

## Cost

These calls use shell builtins only: a file tool with no pins, `Read` (a path inside the plugin costs a change of directory, still a builtin), and any shell command on the read-only allowlist (it can neither write nor push). Any other shell command needs reading when it runs outside a repository, when it mentions `push`, when pins are active and it mentions a write form or a change of directory, or, without pins, when it changes directory (`cd`, `-C`, `-c`, `eval`). Pins add one `cksum` to check the seal, and reading a command adds one `awk`. CI asserts p95 under 15 ms without pins and under 30 ms with pins on Linux.

## Failure mode

The hook always exits 0 and does not set `onFailure`: if it is missing, crashes or times out (10 s), the call goes ahead. A pinned test changed anyway is caught by the green evidence check, which compares the pinned files with the commit they were pinned at.

## Known gaps

These still reach a pinned test, or the default branch, and are left to the green evidence check and the review:

- paths built at run time: variables, the output of command substitution, `xargs` input, `find -exec` or `-delete`, `cd -`;
- programs that write the files they are given or that they choose: formatters and linters with fixes (`prettier --write`, `eslint --fix`), package scripts (`npm run`, `make`), interpreters (`python -c`, `node -e`, scripts), `patch`, `git apply`, `git stash`, `git reset --hard`, `git merge`, `git rebase`, `git pull`;
- wrappers and shells not listed above, and nesting deeper than 32 strings;
- awk programs that write from inside the program (`system()`, `print > "file"`), and other interpreters;
- symbolic links to a pinned file, and Unicode spellings of a name that differ from the pinned one;
- a write into another repository through an absolute path, from a repository without pins;
- `git push` refspecs are read as written: an upstream mapping (`push.default=upstream`, `remote.<name>.push`) that sends another branch to the default one is not seen, and in a repository on the reftable backend, whose refs cannot be read without git, a push with no refspec is not seen and the default branch falls back to `main`/`master`;
- the `PowerShell` tool is not matched.
- the critical-lane gate matches `gh pr create` and `gh pr merge` typed as shell commands; a pull request opened or merged through another client, the web interface or `gh api` is not seen, and a repository without an active ledger is not gated;
- a ledger that cannot be read, or a dispatch that names no task, lets the call through: the review record needs `Task N` in the dispatch description or a `task-N.md` brief path in its prompt.
