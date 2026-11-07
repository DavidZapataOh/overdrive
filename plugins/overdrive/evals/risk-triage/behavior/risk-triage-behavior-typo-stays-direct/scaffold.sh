#!/usr/bin/env bash
# A small library with one typo in its README.
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project mailer
fx_file README.md '# mailer

Send and recieve mail from Node with one function call.'
fx_file src/send.js 'module.exports = function send(to, body) { return { to, body }; };'
fx_file src/send.test.js 'const test = require("node:test");
const assert = require("node:assert");
test("send echoes", () => assert.deepStrictEqual(require("./send")("a", "b"), { to: "a", body: "b" }));'
fx_commit "Add mailer"
