#!/usr/bin/env bash
# Tests for overdrive risk: change collection and path signals.

# shellcheck source=helpers.sh
. "$(dirname "$RUNNER")/risk/helpers.sh"

test_docs_only_is_direct() {
  local repo
  repo=$(make_repo)
  commit_file "$repo" docs/guide.md '# Guide'
  printf 'See the changelog.\n' >> "$repo/docs/guide.md"
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "lane direct"
  assert_no_line "$out" "^item "
  assert_eq "Risk: direct — none" "$(printf '%s\n' "$out" | tail -n 1)"
}

test_auth_segment_is_critical() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/auth/login.ts
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code"
  assert_eq "lane critical" "$(printf '%s\n' "$out" | head -n 1)"
  assert_line "$out" "item auth critical floor path src/auth/login.ts"
  assert_line "$out" "item auth critical floor path src/auth/login.test.ts"
  assert_line "$out" "next Full TDD plan approved by the user; per-task critical review and final review."
  assert_eq "Risk: critical — auth" "$(printf '%s\n' "$out" | tail -n 1)"
}

test_authors_md_is_not_auth() {
  local repo
  repo=$(make_repo)
  write_file "$repo" AUTHORS.md 'Luis'
  source_with_test "$repo" src/author/profile.ts
  source_with_test "$repo" src/authors_list.ts
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
  assert_no_line "$out" "^item "
}

test_path_tokens_skip_documentation_files() {
  local repo
  repo=$(make_repo)
  write_file "$repo" docs/payments.md 'Cards.'
  write_file "$repo" src/auth/README.MD 'Auth.'
  write_file "$repo" guides/billing.mdx 'x'
  write_file "$repo" notes/session.rst 'x'
  write_file "$repo" notes/checkout.adoc 'x'
  write_file "$repo" docs/tenants/diagram.svg '<svg/>'
  write_file "$repo" packages/docs/billing/fee.png 'x'
  write_file "$repo" doc/session/notes.txt 'x'
  risk "$repo" --worktree
  assert_line "$out" "lane direct"
  assert_no_line "$out" "^item "

  # Globs still apply to documentation files, and .txt is documentation only under docs/ or doc/.
  write_file "$repo" .github/workflows/README.md 'x'
  write_file "$repo" lists/passwords.txt 'x'
  risk "$repo" --worktree
  assert_line "$out" "item delivery critical floor path .github/workflows/README.md"
  assert_line "$out" "item auth critical floor path lists/passwords.txt"
  assert_no_line "$out" "path (docs/payments.md|src/auth/README.MD|packages/docs/billing/fee.png)$"
  # Under docs/, only prose, images and fonts are documentation: a docs site's
  # configuration is code.
  write_file "$repo" packages/docs/billing/nav.json '{}'
  risk "$repo" --worktree
  assert_line "$out" "item money critical floor path packages/docs/billing/nav.json"
}

test_rename_out_of_auth_counts_old_path() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/auth/x.ts
  stage_all "$repo"
  git -C "$repo" commit -q -m base
  mkdir -p "$repo/src/misc"
  git -C "$repo" mv src/auth/x.ts src/misc/x.ts
  risk "$repo" --worktree
  assert_line "$out" "item auth critical floor path src/auth/x.ts"
  assert_eq "Risk: critical — auth" "$(printf '%s\n' "$out" | tail -n 1)"

  git -C "$repo" commit -q -m move
  risk "$repo" --diff HEAD~1..HEAD
  assert_line "$out" "item auth critical floor path src/auth/x.ts"

  # A rename into a risky path counts the new path.
  mkdir -p "$repo/src/billing"
  git -C "$repo" mv src/misc/x.ts src/billing/x.ts
  risk "$repo" --staged
  assert_line "$out" "item money critical floor path src/billing/x.ts"
  assert_no_line "$out" "^item auth"
}

test_unicode_and_space_paths() {
  local repo dir='apps/web/src/app/páginas legales'
  repo=$(make_repo)
  source_with_test "$repo" "$dir/page.tsx"
  stage_all "$repo"
  git -C "$repo" commit -q -m base
  printf 'export const title = "Legal";\n' >> "$repo/$dir/page.tsx"
  source_with_test "$repo" 'src/billing/páginas de cobro.ts'
  printf 'path "%s/**" legal-copy standard\n' "$dir" > map.conf
  risk "$repo" --worktree --map "$PWD/map.conf"
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "item legal-copy standard map path $dir/page.tsx"
  assert_line "$out" "item money critical floor path src/billing/páginas de cobro.ts"
  # Spaces are not token separators: "billing page" is one segment.
  source_with_test "$repo" 'src/billing page/x.ts'
  risk "$repo" --worktree
  assert_no_line "$out" "path src/billing page/"
}

test_quote_tab_and_newline_paths() {
  if windows_fs; then return 0; fi
  local repo nl tab
  nl=$(printf '\nx')
  nl=${nl%x}
  tab=$(printf '\t')
  repo=$(make_repo)
  write_file "$repo" "src/auth/say \"hi\".ts" 'x'
  write_file "$repo" "src/billing/a${tab}b.ts" 'x'
  write_file "$repo" 'src/tenants/back\slash.ts' 'x'
  write_file "$repo" ':100644 100644 0 0 M' 'x'
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" 'item auth critical floor path src/auth/say "hi".ts'
  assert_line "$out" 'item money critical floor path src/billing/a\tb.ts'
  assert_line "$out" 'item tenant-isolation critical floor path src/tenants/back\\slash.ts'
  stage_all "$repo"
  git -C "$repo" commit -q -m odd
  risk "$repo" --diff HEAD~1..HEAD
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" 'item money critical floor path src/billing/a\tb.ts'
  assert_line "$out" 'item tenant-isolation critical floor path src/tenants/back\\slash.ts'

  # A newline in any path takes the other reader; both must agree.
  mkdir -p "$repo/src/misc"
  git -C "$repo" mv "src/billing/a${tab}b.ts" "src/misc/a${tab}b.ts"
  write_file "$repo" "src/session/line${nl}break.ts" 'x'
  write_file "$repo" 'src/tenants/back\slash.ts' 'y'
  write_file "$repo" 'src/checkout/páginas "de" cobro.ts' 'x'
  risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" 'item money critical floor path src/checkout/páginas "de" cobro.ts'
  assert_line "$out" 'item auth critical floor path src/session/line\nbreak.ts'
  assert_line "$out" 'item money critical floor path src/billing/a\tb.ts'
  assert_line "$out" 'item tenant-isolation critical floor path src/tenants/back\\slash.ts'
  stage_all "$repo"
  git -C "$repo" commit -q -m newline
  risk "$repo" --diff HEAD~1..HEAD
  assert_line "$out" 'item money critical floor path src/checkout/páginas "de" cobro.ts'
  assert_line "$out" 'item auth critical floor path src/session/line\nbreak.ts'
  assert_line "$out" 'item money critical floor path src/billing/a\tb.ts'
  assert_line "$out" 'item tenant-isolation critical floor path src/tenants/back\\slash.ts'
}

test_binary_file_paths_only() {
  local repo prefix=AK
  repo=$(make_repo)
  mkdir -p "$repo/assets/auth" "$repo/assets/img"
  printf '\000\001%sIA%s\000\377' "$prefix" Q7X2M4P9R3T6V8W1 > "$repo/assets/auth/logo.bin"
  printf '\000\001%sIA%s\000\377' "$prefix" Q7X2M4P9R3T6V8W1 > "$repo/assets/img/blob.bin"
  risk "$repo" --worktree
  assert_line "$out" "item auth critical floor path assets/auth/logo.bin"
  assert_no_line "$out" "secrets"
  assert_no_line "$out" "assets/img/blob.bin"
  stage_all "$repo"
  git -C "$repo" commit -q -m binary
  risk "$repo" --diff HEAD~1..HEAD
  assert_eq "Risk: critical — auth" "$(printf '%s\n' "$out" | tail -n 1)"
}

test_exec_bit_is_standard() {
  local repo
  repo=$(make_repo)
  commit_file "$repo" scripts/build.sh 'echo build'
  chmod +x "$repo/scripts/build.sh"
  git -C "$repo" update-index --chmod=+x scripts/build.sh
  risk "$repo" --worktree
  assert_line "$out" "lane standard"
  assert_line "$out" "item exec-bit standard computed path scripts/build.sh"
  assert_line "$out" "next Short decision plan; TDD where testable; one review at the end of the slice."
  assert_eq "Risk: standard — exec-bit" "$(printf '%s\n' "$out" | tail -n 1)"

  # A new executable file is not a mode change.
  write_file "$repo" scripts/new.sh 'echo new'
  stage_all "$repo"
  git -C "$repo" update-index --chmod=+x scripts/new.sh
  risk "$repo" --staged
  assert_no_line "$out" "path scripts/new.sh"
}

test_deleted_file_is_standard() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/legacy.ts
  write_file "$repo" docs/old.md '# Old'
  stage_all "$repo"
  git -C "$repo" commit -q -m base
  git -C "$repo" rm -q src/legacy.ts
  rm "$repo/docs/old.md"
  risk "$repo" --worktree
  assert_line "$out" "item deletion standard computed path src/legacy.ts"
  assert_line "$out" "item deletion standard computed path docs/old.md"
  assert_eq "Risk: standard — deletion" "$(printf '%s\n' "$out" | tail -n 1)"
}

test_deleted_file_keeps_path_signals() {
  local repo
  repo=$(make_repo)
  write_file "$repo" src/billing/fee.md 'x'
  write_file "$repo" src/billing/fee.ts 'x'
  stage_all "$repo"
  git -C "$repo" commit -q -m base
  git -C "$repo" rm -q src/billing/fee.ts
  risk "$repo" --staged
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
  assert_line "$out" "item deletion standard computed path src/billing/fee.ts"
  assert_eq "Risk: critical — money, deletion" "$(printf '%s\n' "$out" | tail -n 1)"
}

test_project_map_path_rule() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf '# Pricing is reviewed as critical.
path apps/web/src/lib/pricing/** pricing
path content/** copy standard
pathtoken ranking ranking'
  stage_all "$repo"
  git -C "$repo" commit -q -m map
  source_with_test "$repo" apps/web/src/lib/pricing/table.ts
  risk "$repo" --worktree
  assert_line "$out" "item pricing critical map path apps/web/src/lib/pricing/table.ts"
  assert_no_line "$out" "^note risk-map missing"
  assert_eq "Risk: critical — pricing" "$(printf '%s\n' "$out" | tail -n 1)"

  git -C "$repo" stash -q -u
  write_file "$repo" content/home.md '# Home'
  source_with_test "$repo" src/Ranking/score.ts
  risk "$repo" --worktree
  assert_line "$out" "item copy standard map path content/home.md"
  assert_line "$out" "item ranking critical map path src/Ranking/score.ts"
  assert_eq "Risk: critical — ranking, copy" "$(printf '%s\n' "$out" | tail -n 1)"

  # --map replaces the project map; floors always apply.
  printf 'path content/** marketing standard\n' > other.conf
  risk "$repo" --worktree --map "$PWD/other.conf"
  assert_line "$out" "item marketing standard map path content/home.md"
  assert_no_line "$out" "^item (copy|ranking) "
}

test_map_missing_is_noted() {
  local repo
  repo=$(make_repo)
  write_file "$repo" README.md 'x'
  risk "$repo" --worktree
  assert_line "$out" "note risk-map missing"
  assert_line "$out" "next Work inline; test first if testable; verify with evidence."
}

test_invalid_project_map_fails_closed() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'bogus apps/** admin'
  stage_all "$repo"
  git -C "$repo" commit -q -m map
  write_file "$repo" README.md 'x'
  risk "$repo" --worktree
  assert_eq 3 "$rc" "exit code"
  assert_line "$out" "lane critical"
  assert_line "$out" "item classification-failed critical failure invalid risk map"
  assert_eq "Risk: critical — classification-failed" "$(printf '%s\n' "$out" | tail -n 1)"
}

test_untracked_file_counted_in_worktree_mode() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .gitignore 'ignored/'
  stage_all "$repo"
  git -C "$repo" commit -q -m ignore
  source_with_test "$repo" src/billing/new.ts
  write_file "$repo" ignored/auth.ts 'x'
  risk "$repo" --worktree
  assert_line "$out" "item money critical floor path src/billing/new.ts"
  assert_no_line "$out" "ignored/auth.ts"
  risk "$repo" --staged
  assert_line "$out" "lane direct"
}

test_paths_mode_without_git_changes() {
  local repo
  repo=$(make_repo)
  risk "$repo" --paths src/auth/login.ts ./docs/../src/billing/plan.ts docs/session.md
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "item auth critical floor path src/auth/login.ts"
  assert_line "$out" "item money critical floor path src/billing/plan.ts"
  assert_no_line "$out" "docs/session.md"
  assert_eq "Risk: critical — auth, money" "$(printf '%s\n' "$out" | tail -n 1)"
  # Absolute paths inside the repository are made relative to its root.
  risk "$repo" --paths "$repo/src/checkout/x.ts" --staged
  assert_line "$out" "item money critical floor path src/checkout/x.ts"
  risk "$repo" --paths "$(dirname "$repo")//$(basename "$repo")/./src/checkout/x.ts"
  assert_line "$out" "item money critical floor path src/checkout/x.ts"
  # Either spelling of a repository reached through a symlink.
  if ! windows_fs; then
    ln -s "$repo" link
    risk link --paths "$PWD/link/src/auth/a.ts" "$(cd "$repo" && pwd -P)/src/billing/b.ts"
    assert_line "$out" "item auth critical floor path src/auth/a.ts"
    assert_line "$out" "item money critical floor path src/billing/b.ts"
  fi
}

test_modes_combine() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/auth/a.ts
  stage_all "$repo"
  git -C "$repo" commit -q -m auth
  source_with_test "$repo" src/billing/b.ts
  git -C "$repo" add src/billing
  write_file "$repo" Dockerfile 'FROM scratch'
  risk "$repo" --diff HEAD~1..HEAD --staged --paths src/tenants/c.ts
  assert_line "$out" "item auth critical floor path src/auth/a.ts"
  assert_line "$out" "item money critical floor path src/billing/b.ts"
  assert_line "$out" "item tenant-isolation critical floor path src/tenants/c.ts"
  assert_no_line "$out" "Dockerfile"
  assert_eq "Risk: critical — auth, money, tenant-isolation" "$(printf '%s\n' "$out" | tail -n 1)"
}

test_three_dot_range() {
  local repo
  repo=$(make_repo)
  git -C "$repo" checkout -q -b topic
  source_with_test "$repo" src/billing/b.ts
  stage_all "$repo"
  git -C "$repo" commit -q -m topic
  git -C "$repo" checkout -q -
  source_with_test "$repo" src/auth/a.ts
  stage_all "$repo"
  git -C "$repo" commit -q -m main
  risk "$repo" --diff HEAD...topic
  assert_line "$out" "item money critical floor path src/billing/b.ts"
  assert_no_line "$out" "src/auth"
}

test_bare_repo_diff_mode_reads_map_from_commit() {
  local repo bare
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'pathtoken ranking ranking'
  stage_all "$repo"
  git -C "$repo" commit -q -m map
  source_with_test "$repo" src/ranking/score.ts
  stage_all "$repo"
  git -C "$repo" commit -q -m score
  bare=$PWD/bare.git
  git clone -q --bare "$repo" "$bare"
  risk "$bare" --diff HEAD~1..HEAD
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item ranking critical map path src/ranking/score.ts"
  risk "$bare" --worktree
  assert_eq 3 "$rc" "worktree mode needs a working tree"
  assert_line "$out" "lane critical"
}

test_repo_found_from_nested_cwd() {
  local repo
  repo=$(make_repo)
  source_with_test "$repo" src/auth/x.ts
  mkdir -p "$repo/src/deep"
  # Relative --paths are relative to the repository root, not to the current directory.
  out=$(cd "$repo/src/deep" && CLAUDE_PROJECT_DIR=$PWD overdrive risk --worktree --paths src/billing/y.ts)
  assert_line "$out" "item auth critical floor path src/auth/x.ts"
  assert_line "$out" "item money critical floor path src/billing/y.ts"
}

test_outside_git_fails_closed() {
  mkdir plain
  rc=0
  out=$(cd plain && overdrive risk --worktree 2>/dev/null) || rc=$?
  assert_eq 3 "$rc" "exit code"
  assert_line "$out" "item classification-failed critical failure not a git repository"
}

test_usage_errors_exit_64() {
  local repo
  repo=$(make_repo)
  assert_exit 64 overdrive risk --repo "$repo"
  assert_exit 64 overdrive risk --repo "$repo" --bogus
  assert_exit 64 overdrive risk --repo "$repo" --diff
  assert_exit 64 overdrive risk --repo "$repo" --diff HEAD
  assert_exit 64 overdrive risk --repo "$repo" --paths
}

test_unborn_head_fails_closed() {
  local repo=$PWD/unborn mode
  git init -q "$repo"
  write_file "$repo" src/a.ts 'x'
  git -C "$repo" add -A
  for mode in --staged --worktree '--paths src/a.ts' '--diff HEAD..HEAD'; do
    # shellcheck disable=SC2086
    risk "$repo" $mode
    assert_eq 3 "$rc" "exit code for $mode"
    assert_line "$out" "lane critical"
    assert_line "$out" "item classification-failed critical failure no commits yet"
    assert_eq "Risk: critical — classification-failed" "$(printf '%s\n' "$out" | tail -n 1)"
  done
}

test_paths_relative_to_cwd_inside_repo() {
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/src/billing"
  # From a subdirectory a relative path may be written either way; both are judged.
  out=$(cd "$repo/src/billing" && overdrive risk --paths fee.ts src/auth/x.ts)
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
  assert_line "$out" "item auth critical floor path src/auth/x.ts"
  out=$(cd "$repo/src/billing" && overdrive risk --repo "$repo" --paths fee.ts)
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
}

test_camel_case_and_digit_tokens() {
  local repo
  repo=$(make_repo)
  risk "$repo" --paths src/PaymentService.ts src/AuthController.ts src/userSessions.ts \
    src/sessionStore.ts src/oauth2/cb.ts src/authentication/a.ts src/authorization/b.ts \
    src/OAuthToken.ts src/JWTSecret.ts src/Author.tsx src/Charger.ts src/Authors2.ts
  assert_line "$out" "item money critical floor path src/PaymentService.ts"
  for p in AuthController.ts userSessions.ts sessionStore.ts oauth2/cb.ts authentication/a.ts \
    authorization/b.ts OAuthToken.ts JWTSecret.ts; do
    assert_line "$out" "item auth critical floor path src/$p"
  done
  assert_no_line "$out" "path src/(Author.tsx|Charger.ts|Authors2.ts)$"
}

test_symlink_target_is_evaluated() {
  if windows_fs; then return 0; fi
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/src/misc" "$repo/src/billing"
  ln -s ../billing/fee.ts "$repo/src/misc/link.ts"
  risk "$repo" --worktree
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
  git -C "$repo" add -A
  risk "$repo" --staged
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
  git -C "$repo" commit -q -m link
  risk "$repo" --diff HEAD~1..HEAD
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
  # A changed target counts too, through the working tree.
  ln -sfn ../auth/x.ts "$repo/src/misc/link.ts"
  risk "$repo" --worktree
  assert_line "$out" "item auth critical floor path src/auth/x.ts"
  git -C "$repo" clone -q --bare "$repo" "$PWD/bare.git"
  risk "$PWD/bare.git" --diff HEAD~1..HEAD
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item money critical floor path src/billing/fee.ts"
}

test_paths_double_dash_ends_options() {
  local repo
  repo=$(make_repo)
  risk "$repo" --paths src/a.ts -- --odd/auth.ts --staged
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "item auth critical floor path --odd/auth.ts"
  risk "$repo" --paths -- --billing.ts
  assert_line "$out" "item money critical floor path --billing.ts"
}
