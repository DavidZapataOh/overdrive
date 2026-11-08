#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
fx_git_repo
fx_node_project portal
fx_risk_map "pathtoken billing money" "pathtoken migrations data-migration"
fx_file src/config.js "exports.serviceUrl = process.env.SERVICE_URL;"
fx_file README.md "# Portal

## Setup

Set the API_URL environment variable to the service address, then run npm start."
fx_file test/config.test.js "const test = require('node:test');
const assert = require('node:assert');
test('config exposes serviceUrl', () => assert.ok('serviceUrl' in require('../src/config.js')));"
fx_commit "Initial commit"
