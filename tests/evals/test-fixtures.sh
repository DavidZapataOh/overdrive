#!/usr/bin/env bash
# shellcheck disable=SC2016 # single quotes are deliberate: the text is evaluated or matched later
# Tests for plugins/overdrive/evals/_lib/fixtures.sh.

# The native Windows jq writes CRLF unless told otherwise (-b); elsewhere the flag does nothing.
jq() { command jq -b "$@"; }

root=$(dirname "$(dirname "$RUNNER")")
overdrive() { bash "$root/plugins/overdrive/bin/overdrive" "$@"; }

# scaffold BODY: runs BODY the way an eval scaffold script does: from a case directory three
# levels below the evals root that holds _lib, in an empty workspace.
scaffold() {
  local evals=$PWD/evals case_dir=$PWD/evals/tdd/behavior/case
  mkdir -p "$case_dir" ws
  cp -R "$root/plugins/overdrive/evals/_lib" "$evals/_lib"
  printf '#!/usr/bin/env bash\nsource "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1\n%s\n' "$1" > "$case_dir/scaffold.sh"
  (cd ws && bash "$case_dir/scaffold.sh")
}

test_git_repo_commits_without_global_identity() {
  scaffold 'fx_git_repo; fx_file src/a.txt one; fx_commit "first"; fx_file src/a.txt two; fx_commit "second"'
  assert_eq "main" "$(git -C ws symbolic-ref --short HEAD)"
  assert_eq "2" "$(git -C ws rev-list --count HEAD)"
  assert_eq "second" "$(git -C ws log -1 --format=%s)"
  assert_eq "" "$(git -C ws status --porcelain)"
}

test_commit_allows_an_empty_first_commit() {
  scaffold 'fx_git_repo; fx_commit "empty"'
  assert_eq "1" "$(git -C ws rev-list --count HEAD)"
}

test_node_project_runs_the_builtin_test_runner_without_installs() {
  scaffold 'fx_node_project billing'
  assert_eq "billing" "$(jq -r .name ws/package.json)"
  assert_eq "node --test" "$(jq -r .scripts.test ws/package.json)"
  assert_eq "null" "$(jq -r .dependencies ws/package.json)"
  [ ! -e ws/node_modules ] || return 1
}

test_file_creates_parent_directories_and_keeps_content_verbatim() {
  scaffold 'fx_file "apps/web/src/páginas legales/page.tsx" "export const x = \"\$HOME\";"'
  assert_eq 'export const x = "$HOME";' "$(cat "ws/apps/web/src/páginas legales/page.tsx")"
}

test_risk_map_writes_one_rule_per_argument_and_parses() {
  scaffold 'fx_git_repo; fx_risk_map "path packages/db/** data-migration" "keyword refund money"; fx_commit base'
  assert_eq "2" "$(wc -l < ws/.overdrive/risk-map.conf | tr -d ' ')"
  assert_line "$(cat ws/.overdrive/risk-map.conf)" "path packages/db/** data-migration"
  out=$(overdrive risk --repo ws --paths packages/db/schema.sql)
  assert_line "$out" "Risk: critical — data-migration"
}

test_decisions_log_passes_the_decisions_checker() {
  scaffold 'fx_decisions "$(printf "## D-0001 — Use Wompi\n- Date: 2026-01-02\n- Scope: payments\n- Decision: Wompi is the only processor.\n- Source: \"use wompi\" — Ana, 2026-01-02\n- Why: local cards.\n- Cost if wrong: migration.\n- Status: active")"'
  assert_exit 0 overdrive decisions check ws/.overdrive/decisions.md
  assert_eq "D-0002" "$(overdrive decisions next-id ws/.overdrive/decisions.md)"
}

test_claude_md_is_an_ordinary_file() {
  scaffold 'fx_claude_md "Reply in Spanish."'
  assert_eq "Reply in Spanish." "$(cat ws/CLAUDE.md)"
}

test_missing_arguments_fail() {
  assert_exit 1 scaffold 'fx_node_project'
  assert_exit 1 scaffold 'fx_commit'
}

test_plugin_writes_a_manifest_and_skills_directory() {
  scaffold 'fx_plugin acme-tools "Release helpers"'
  assert_eq "acme-tools" "$(jq -r .name ws/.claude-plugin/plugin.json)"
  assert_eq "Release helpers" "$(jq -r .description ws/.claude-plugin/plugin.json)"
  [ -d ws/skills ] || { echo "skills/ missing" >&2; return 1; }
}

test_plugin_requires_a_name() {
  assert_exit 1 scaffold 'fx_plugin'
}
