# Security policy

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use GitHub's private vulnerability reporting: open the **Security** tab of this repository and choose **Report a vulnerability** (Security advisories). The report stays visible only to the maintainer until a fix is ready.

Include what you found, the steps to reproduce it and the version of the plugin (`overdrive version`). Reports are handled in writing, in the advisory thread.

## Scope

Overdrive runs hooks and a shell CLI on your machine inside Claude Code. Reports about the guard being bypassed, a hook or CLI command running unintended code, or the plugin reading or writing outside the repository it is working in are in scope. The guard's documented gaps are listed in [docs/guard.md](docs/guard.md).

## Supported versions

Fixes go to the latest release.
