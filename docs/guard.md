# Tool-call guard

Overdrive registers a `PreToolUse` hook on `Edit`, `Write`, `MultiEdit`, `NotebookEdit` and `Bash`. It enforces the rules that must hold on every call; everything else is left to the skills and the review.

## What it does

It denies only what it recognizes: edits through the file tools, and the shell forms listed below. Anything else that changes a pinned test is caught later by the green evidence check (see Known gaps).

| Call | Result |
| --- | --- |
| `Edit`, `Write`, `MultiEdit` or `NotebookEdit` on a pinned test (listed in `.overdrive/run/pins` of the file's repository) | denied: `<path> is a pinned test. Tests change only before the red run. If the test itself is wrong, run: overdrive pin --release "<reason>" and redo red.` |
| A file tool on `.overdrive/run/pins` while it exists | denied |
| Any file-tool edit, or recognized shell write, in a repository whose pins file cannot be read, does not parse or fails its seal | denied until `overdrive pin --release "<reason>"` |
| A shell command whose recognized write reaches a pinned test: redirections (`>`, `>>`, `>\|`, `&>`), `tee`, `sed -i`, `perl -i`, `rm`, `mv`, `cp`, `ln`, `install`, `truncate`, `dd of=`, `unlink`, `shred`, `sort -o`/`--output`, `awk`/`gawk -i inplace`, `uniq IN OUT`, `git checkout`, `git restore`, `git rm`, `git mv` | denied; a directory or glob that covers a pinned test counts, including the repository itself, a folder above it and `/` |
| `git switch`, or `git checkout` of a branch or commit (any operand that is not an existing path, or `-b`, `-B`, `--orphan`, `--detach`), in a repository with pins | denied: finish green and `overdrive pin --clear`, or release |
| `git push` that would update the default branch: an explicit refspec (`main`, `+main`, `HEAD:main`, `heads/main`, `refs/heads/main`, a wildcard), a push with no refspec while `HEAD` is on it, `--all`, `--mirror`, `--delete` of it | denied, with or without `--force` |
| A file tool call, or a shell command outside a small read-only allowlist, that goes ahead | writes `.overdrive/run/markers/<session_id>.changed` in every repository it runs in, once: the commit the change starts from and a checksum of the branches, tags and stash; a file tool also leaves `<session_id>.edited` |
| The plugin's own read-only commands, run by the CLI's absolute path: `overdrive risk`, `overdrive decisions next-id`, `overdrive decisions check`, `overdrive recall`, with only plain words and quoted strings after them (no `;`, `&`, `\|`, redirection, `$`, backquote, glob or `~` outside quotes) | allowed without a permission prompt (`permissionDecision: allow`); deny and ask rules in the user's settings still apply |

The shell reader follows quotes, escapes, comments, line continuations, here-documents, `cd`, `pushd`/`popd`, subshells and `$(...)` (a `cd` inside them ends with them), `git -C`, the wrappers `sudo`, `env`, `nice`, `timeout`, `stdbuf`, `nohup`, `command`, `builtin`, `exec`, `time`, `xargs` and `ionice`, and the strings run by `sh -c`, `bash -c` and `eval`.

The repository is found from the file's own path, or from the call's `cwd` and each directory the command moves to, never from the session's project directory: a session that starts above the repository still finds it, and a call outside any repository is a no-op. The default branch is the one `refs/remotes/<remote>/HEAD` points at; without it, both `main` and `master` are protected. Linked worktrees are followed through their `.git` file. On macOS and Windows, paths compare without case.

## Cost

These calls use shell builtins only: a file tool with no pins, and any shell command on the read-only allowlist (it can neither write nor push). Any other shell command needs reading when it runs outside a repository, when it mentions `push`, when pins are active and it mentions a write form or a change of directory, or, without pins, when it changes directory (`cd`, `-C`, `-c`, `eval`). Pins add one `cksum` to check the seal, and reading a command adds one `awk`. CI asserts p95 under 15 ms without pins and under 30 ms with pins on Linux.

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
