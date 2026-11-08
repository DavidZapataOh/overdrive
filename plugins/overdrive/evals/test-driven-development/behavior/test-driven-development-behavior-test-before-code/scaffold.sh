#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/../text-project.sh" || exit 1
td_text_project
git rm -q test/text.test.js && fx_commit "Drop the text tests"
