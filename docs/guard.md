# Tool-call guard

Overdrive registers a `PreToolUse` hook on `Edit`, `Write`, `MultiEdit`, `NotebookEdit` and `Bash`. It enforces the rules that must hold on every call; everything else is left to the skills and the review.

## What it does

| Call | Result |
| --- | --- |
| A file tool on a pinned test (`.overdrive/run/pins` of the file's repository) | denied: `<path> is a pinned test. Tests change only before the red run. If the test itself is wrong, run: overdrive pin --release "<reason>" and redo red.` |
| A file tool on `.overdrive/run/pins` while it exists | denied |
| Any change in a repository whose pins file fails to parse or its seal | denied until `overdrive pin --release "<reason>"` |
| A shell command that writes a pinned test: `>`, `>>`, `&>`, `tee`, `sed -i`, `perl -i`, `rm`, `mv`, `cp`, `ln`, `install`, `truncate`, `dd of=`, `unlink`, `shred`, `git checkout`, `git restore`, `git rm`, `git mv` | denied; a directory or glob that covers a pinned test counts |
| `git push` that would update the default branch: an explicit refspec (`main`, `+main`, `HEAD:main`, `refs/heads/main`, a wildcard), a push with no refspec while `HEAD` is on it, `--all`, `--mirror`, `--delete` of it | denied, with or without `--force` |
| A file tool call, or a shell command outside a small read-only allowlist, that goes ahead | touches `.overdrive/run/markers/<session_id>.changed` in the repository |

The repository is found from the file's own path, or from the call's `cwd` (and any `cd` or `git -C` in the command), never from the session's project directory: a session that starts above the repository still finds it, and a call outside any repository is a no-op. The default branch is the one `refs/remotes/<remote>/HEAD` points at; without it, both `main` and `master` are protected. Linked worktrees are followed through their `.git` file. On macOS and Windows, paths compare without case.

## Cost

A call with no pins and no push or file-writing command uses shell builtins only. A repository with pins adds one `cksum` to check the seal; a shell command that pushes, or that may write a file where pins are active, adds one `awk` to read the command. CI asserts p95 under 15 ms without pins and under 30 ms with pins on Linux.

## Failure mode

The hook always exits 0 and does not set `onFailure`: if it is missing, crashes or times out (10 s), the call goes ahead. A pinned test changed anyway is caught by the green evidence check, which compares the pinned files with the commit they were pinned at.

## Known gaps

The shell reader follows quotes, escapes, comments, here-documents, `cd` and `git -C`, but it is not a shell. These still reach a pinned test, and are left to the green evidence check:

- paths built at run time: variables, command substitution, `xargs` input, `find -exec` or `-delete`;
- programs that write files they are given: formatters (`prettier --write`, `eslint --fix`), interpreters (`python -c`, `node -e`), `patch`, `git apply`, `git stash`, `git reset --hard` to another commit;
- symbolic links to a pinned file, and Unicode spellings of a name that differ from the pinned one;
- a write into another repository through an absolute path, from a repository without pins.

`git push` refspecs are read as written: a push whose upstream mapping (`push.default=upstream`, `remote.<name>.push`) sends another branch to the default one is not seen. The `PowerShell` tool is not matched.
