#!/usr/bin/env bash
# Tests for overdrive risk: lane resolution and the output contract.

# shellcheck source=helpers.sh
. "$(dirname "$RUNNER")/risk/helpers.sh"

# kinds: the line kinds of $out in order, repeats collapsed.
kinds() {
  printf '%s\n' "$out" | awk '{ k = ($1 == "Risk:") ? "risk" : $1 } k != last { print k; last = k }' | paste -s -d ' ' -
}

test_lane_is_max_of_items() {
  local repo
  repo=$(make_repo)
  write_file "$repo" package.json '{}'
  risk "$repo" --worktree
  assert_eq "lane standard" "$(printf '%s\n' "$out" | head -n 1)"
  assert_line "$out" "next Short decision plan; TDD where testable; one review at the end of the slice."
  source_with_test "$repo" src/billing/fee.ts
  risk "$repo" --worktree
  assert_eq "lane critical" "$(printf '%s\n' "$out" | head -n 1)"
  assert_line "$out" "next Full TDD plan approved by the user; per-task critical review and final review."
}

test_risk_line_format_exact() {
  local repo
  repo=$(make_repo)
  write_file "$repo" package.json '{}'
  source_with_test "$repo" src/billing/fee.ts
  source_with_test "$repo" src/auth/login.ts
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code"
  assert_eq "Risk: critical — auth, money, dependencies" "$(risk_line)"
  assert_eq "lane item note next risk" "$(kinds)"
  # Critical items first, then standard, each sorted; evidence keeps the reading order.
  assert_eq "auth auth money money dependencies" \
    "$(printf '%s\n' "$out" | awk '$1 == "item" { print $2 }' | paste -s -d ' ' -)"
  assert_line "$out" "item dependencies standard floor path package.json"
  assert_line "$out" "note risk-map missing"
}

test_risk_line_none() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'pathtoken ranking ranking'
  commit_all "$repo" map
  write_file "$repo" README.md 'Hello'
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code"
  assert_eq "lane direct
next Work inline; test first if testable; verify with evidence.
Risk: direct — none" "$out"
}

test_items_are_deduplicated_across_modes() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/billing/fee.ts
  git -C "$repo" add -A
  risk "$repo" --staged --worktree --paths src/billing/fee.ts
  assert_eq 1 "$(printf '%s\n' "$out" | grep -c '^item money critical floor path src/billing/fee.ts$')"
}

test_risk_map_change_is_critical() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'pathtoken ranking ranking'
  commit_all "$repo" map
  printf 'pathtoken ledger money\n' >> "$repo/.overdrive/risk-map.conf"
  risk "$repo" --worktree
  assert_line "$out" "item risk-map critical floor path .overdrive/risk-map.conf"
  assert_eq "Risk: critical — risk-map" "$(risk_line)"
}

test_map_change_cannot_lower_its_own_lane() {
  local repo bare
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'pathtoken ranking ranking'
  commit_all "$repo" map
  # The change drops the rule and touches a file only that rule covers.
  printf 'pathtoken unrelated other\n' > "$repo/.overdrive/risk-map.conf"
  source_with_test "$repo" src/ranking/score.ts
  risk "$repo" --worktree
  assert_line "$out" "item ranking critical map path src/ranking/score.ts"
  git -C "$repo" add -A
  risk "$repo" --staged
  assert_line "$out" "item ranking critical map path src/ranking/score.ts"
  git -C "$repo" commit -q -m drop-rule
  bare=$PWD/bare.git
  git clone -q --bare "$repo" "$bare"
  risk "$bare" --diff HEAD~1..HEAD
  assert_line "$out" "item ranking critical map path src/ranking/score.ts"
  risk "$bare" --diff HEAD~1...HEAD
  assert_line "$out" "item ranking critical map path src/ranking/score.ts"

  # Rules the change adds apply too.
  printf 'pathtoken unrelated other\npathtoken scoring scoring\n' > "$repo/.overdrive/risk-map.conf"
  source_with_test "$repo" src/scoring/x.ts
  risk "$repo" --worktree
  assert_line "$out" "item scoring critical map path src/scoring/x.ts"
}

test_paths_mode_reads_head_map_in_bare_repo() {
  local repo bare
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'keyword cobro money'
  commit_all "$repo" map
  bare=$PWD/bare.git
  git clone -q --bare "$repo" "$bare"
  risk "$bare" --intent "el cobro"
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" 'item money critical map keyword "cobro"'
}
