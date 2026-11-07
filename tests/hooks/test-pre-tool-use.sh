#!/usr/bin/env bash
# Tests for plugins/overdrive/hooks/pre-tool-use.

plugin_dir() { printf '%s\n' "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive"; }

od() { "$BASH" "$(plugin_dir)/bin/overdrive" "$@"; }

jstr() {
  # shellcheck source=../../plugins/overdrive/lib/json.sh
  . "$(plugin_dir)/lib/json.sh"
  json_escape "$1"
}

# file_event TOOL PATH [CWD] [SID]: a PreToolUse event for a file tool.
file_event() {
  local key=file_path
  [ "$1" != NotebookEdit ] || key=notebook_path
  printf '{"session_id":"%s","transcript_path":"/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"%s":"%s","old_string":"a \\"cwd\\": \\"x\\"","new_string":"b"},"tool_use_id":"toolu_1"}' \
    "$(jstr "${4:-sess-1}")" "$(jstr "${3:-$PWD}")" "$1" "$key" "$(jstr "$2")"
}

# bash_event COMMAND [CWD] [SID]
bash_event() {
  printf '{"session_id":"%s","transcript_path":"/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"x"},"tool_use_id":"toolu_1"}' \
    "$(jstr "${3:-sess-1}")" "$(jstr "${2:-$PWD}")" "$(jstr "$1")"
}

# guard EVENT: run the hook as Claude Code does, with a project dir that must not matter.
guard() {
  printf '%s' "$1" | CLAUDE_PLUGIN_ROOT="$(plugin_dir)" CLAUDE_PROJECT_DIR=/nonexistent "$(plugin_dir)/hooks/pre-tool-use"
}

assert_allows() {
  local out rc=0
  out=$(guard "$1") || rc=$?
  assert_eq 0 "$rc" "exit code"
  assert_eq '' "$out" "stdout of an allowed call"
}

# assert_denies EVENT REASON: exit 0 with a deny decision whose reason contains REASON.
assert_denies() {
  local out rc=0
  out=$(guard "$1") || rc=$?
  assert_eq 0 "$rc" "exit code"
  case $out in
    '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'*'"}}') ;;
    *) printf 'not a deny: %s\n' "$out" >&2; return 1 ;;
  esac
  # shellcheck source=../../plugins/overdrive/lib/json.sh
  . "$(plugin_dir)/lib/json.sh"
  json_extract_string permissionDecisionReason "$out"
  case $JSON_VALUE in
    *"$2"*) ;;
    *) printf 'reason lacks: %s\n  got: %s\n' "$2" "$JSON_VALUE" >&2; return 1 ;;
  esac
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$out" | python3 -m json.tool >/dev/null
  fi
}

# The command is named by its absolute path: bin/ is not on the Bash tool's PATH.
pin_reason() {
  printf '%s is a pinned test. Tests change only before the red run. If the test itself is wrong, run: %s/bin/overdrive pin --release "<reason>" and redo red.' "$1" "$(plugin_dir)"
}

# main_repo: a repo on branch main whose origin's default branch is main.
main_repo() {
  local repo
  repo=$(make_repo)
  git -C "$repo" branch -q -M main
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  printf '%s\n' "$repo"
}

# odd_name: a test file name with an accent, a space and quotes (Windows forbids ").
odd_name() {
  if is_windows; then
    printf '%s\n' "tests/páginas legales/it's q.test.sh"
  else
    printf '%s\n' "tests/páginas legales/it's \"q\".test.sh"
  fi
}

# pinned_repo: tests/cart total.test.sh and tests/páginas legales pinned, src free.
pinned_repo() {
  local repo
  repo=$(main_repo)
  commit_file "$repo" "tests/cart total.test.sh" 'assert total 10'
  commit_file "$repo" "$(odd_name)" 'assert'
  commit_file "$repo" src/cart.sh 'total=0'
  (cd "$repo" && od pin "tests/cart total.test.sh" "tests/páginas legales") >/dev/null
  printf '%s\n' "$repo"
}

is_windows() {
  case $(uname -s) in MINGW* | MSYS* | CYGWIN*) return 0 ;; esac
  return 1
}

test_guard_noop_outside_git() {
  local plain
  mkdir -p plain/sub
  plain=$PWD/plain
  # The session started above the repository: nothing here is a repo.
  GIT_CEILING_DIRECTORIES=$PWD assert_allows "$(file_event Edit "$plain/sub/a.txt" "$plain")"
  assert_allows "$(file_event Write "$plain/new/b.txt" "$plain")"
  assert_allows "$(bash_event 'rm -rf sub && echo hi > x.txt' "$plain")"
  assert_allows "$(bash_event 'git push origin main' "$plain")"
  [ ! -e plain/.overdrive ] || { echo "created state outside git" >&2; return 1; }
}

test_guard_fast_path_without_pins() {
  local repo
  repo=$(main_repo)
  assert_allows "$(file_event Edit "$repo/src/a.ts" "$repo")"
  assert_allows "$(bash_event 'npm test' "$repo")"
  assert_allows "$(bash_event 'sed -i.bak s/a/b/ tests/x.test.sh' "$repo")"
  # No forks once the session has marked the repository (every call after its first):
  # with PATH unusable, any external command would fail to resolve.
  mkdir -p "$repo/.overdrive/run/markers"
  printf 'start\n' > "$repo/.overdrive/run/markers/fast.changed"
  printf 'start\n' > "$repo/.overdrive/run/markers/fast2.changed"
  out=$(file_event Edit "$repo/src/a.ts" "$repo" fast | PATH=/nonexistent "$BASH" "$(plugin_dir)/hooks/pre-tool-use" 2>&1)
  assert_eq '' "$out"
  out=$(bash_event 'npm test' "$repo" fast2 | PATH=/nonexistent "$BASH" "$(plugin_dir)/hooks/pre-tool-use" 2>&1)
  assert_eq '' "$out"
  assert_eq start "$(cat "$repo/.overdrive/run/markers/fast.changed")" "marker rewritten"
}

test_marker_records_start_and_session_roots() {
  local repo head data m
  # Spelled as the hook spells it (TMPDIR may end in a slash).
  repo=$(cd "$(main_repo)" && pwd)
  commit_file "$repo" src/a.ts 'a'
  head=$(git -C "$repo" rev-parse HEAD)
  data=$PWD/data
  m=$repo/.overdrive/run/markers/sess-R.changed
  CLAUDE_PLUGIN_DATA=$data assert_allows "$(file_event Edit "$repo/src/a.ts" "$repo" sess-R)"
  # The commit the change started from, so committed work stays visible at Stop.
  assert_eq "$head" "$(sed -n 1p "$m")" "start commit"
  # The refs as they were, so a commit on another branch or a stash shows at Stop.
  case $(sed -n 2p "$m") in 'refs '[0-9]*) ;; *) echo "no refs checksum: $(sed -n 2p "$m")" >&2; return 1 ;; esac
  [ -f "${m%.changed}.edited" ] || { echo "file tool not recorded" >&2; return 1; }
  assert_eq "$repo" "$(cat "$data/sessions/sess-R.roots")" "session roots"
  # Later calls neither move the start nor list the repository again.
  commit_file "$repo" src/b.ts 'b'
  CLAUDE_PLUGIN_DATA=$data assert_allows "$(bash_event 'npm run build' "$repo" sess-R)"
  assert_eq "$head" "$(sed -n 1p "$m")" "start commit after a commit"
  assert_eq "$repo" "$(cat "$data/sessions/sess-R.roots")" "session roots after a second call"
  # A repository without commits starts unborn.
  repo=$PWD/unborn
  git init -q "$repo"
  CLAUDE_PLUGIN_DATA=$data assert_allows "$(file_event Write "$repo/a.txt" "$repo" sess-R)"
  assert_eq unborn "$(sed -n 1p "$repo/.overdrive/run/markers/sess-R.changed")" "unborn start"
  assert_eq "$repo" "$(sed -n 2p "$data/sessions/sess-R.roots")" "second root"
}

test_denies_edit_of_pinned_test() {
  local repo
  repo=$(pinned_repo)
  assert_denies "$(file_event Edit "$repo/tests/cart total.test.sh" "$repo")" "$(pin_reason 'tests/cart total.test.sh')"
  assert_denies "$(file_event Write "$repo/$(odd_name)" "$repo/src")" "$(pin_reason "$(odd_name)")"
  assert_denies "$(file_event MultiEdit "$repo/src/../tests/./cart total.test.sh" /)" "$(pin_reason 'tests/cart total.test.sh')"
  assert_denies "$(file_event NotebookEdit "$repo/tests/cart total.test.sh" "$repo")" "$(pin_reason 'tests/cart total.test.sh')"
  # The pins file itself is not a way around the pins.
  assert_denies "$(file_event Write "$repo/.overdrive/run/pins" "$repo")" "$(plugin_dir)/bin/overdrive pin --release"
  if is_windows; then
    # Claude Code sends Windows paths with backslashes and a drive letter.
    local win
    win=$(cd "$repo" && pwd -W)
    win=${win//\//\\}
    assert_denies "$(file_event Edit "$win\\tests\\cart total.test.sh" "$win")" "$(pin_reason 'tests/cart total.test.sh')"
    assert_denies "$(file_event Edit "$win\\TESTS\\Cart Total.test.sh" "$win")" 'is a pinned test'
  fi
}

test_allows_edit_of_other_file() {
  local repo
  repo=$(pinned_repo)
  assert_allows "$(file_event Edit "$repo/src/cart.sh" "$repo")"
  assert_allows "$(file_event Write "$repo/tests/cart total.test.sh.orig" "$repo")"
  assert_allows "$(file_event Write "$repo/tests/new.test.sh" "$repo")"
}

test_denies_on_unparseable_pins() {
  local repo pins
  repo=$(pinned_repo)
  pins=$repo/.overdrive/run/pins
  # A hand edit that drops a pinned path no longer matches the seal.
  grep -v 'cart total' "$pins" > "$pins.new" && mv "$pins.new" "$pins"
  assert_denies "$(file_event Edit "$repo/src/cart.sh" "$repo")" 'overdrive pin --release "<reason>"'
  assert_denies "$(bash_event 'echo x > src/cart.sh' "$repo")" 'overdrive pin --release "<reason>"'
  printf 'garbage\n' > "$pins"
  assert_denies "$(file_event Edit "$repo/src/cart.sh" "$repo")" 'cannot be parsed'
  # Releasing stays possible.
  assert_allows "$(bash_event 'overdrive pin --release "test was wrong"' "$repo")"
  # Another repository is not affected.
  other=$(main_repo)
  assert_allows "$(file_event Edit "$other/src/cart.sh" "$repo")"
}

test_unreadable_pins_deny_quietly() {
  local repo out err rc=0
  repo=$(pinned_repo)
  chmod 000 "$repo/.overdrive/run/pins"
  # Windows and root read the file anyway.
  if is_windows || [ -r "$repo/.overdrive/run/pins" ]; then
    chmod 644 "$repo/.overdrive/run/pins"
    echo "notice: chmod 000 does not block reads here; skipped"
    return 0
  fi
  err=$PWD/err
  out=$(guard "$(file_event Edit "$repo/src/cart.sh" "$repo")" 2>"$err") || rc=$?
  chmod 644 "$repo/.overdrive/run/pins"
  assert_eq 0 "$rc"
  case $out in *'"permissionDecision":"deny"'*'cannot be parsed'*) ;; *) echo "not denied: $out" >&2; return 1 ;; esac
  assert_eq '' "$(cat "$err")" "stderr"
}

test_read_only_commands_skip_the_reader() {
  local plain repo
  mkdir plain
  plain=$PWD/plain
  repo=$(pinned_repo)
  # The only command on PATH is an awk that records being run.
  mkdir bin
  printf '#!%s\n: > "%s/awk-ran"\n' "$BASH" "$PWD" > bin/awk
  chmod +x bin/awk
  for cmd in 'cat format.txt' 'grep -r rm .' 'ls -la | grep perl'; do
    out=$(bash_event "$cmd" "$plain" | PATH=$PWD/bin "$BASH" "$(plugin_dir)/hooks/pre-tool-use" 2>&1)
    assert_eq '' "$out" "$cmd outside a repo"
    [ ! -e awk-ran ] || { echo "reader ran for: $cmd" >&2; return 1; }
  done
  out=$(bash_event 'rm x' "$plain" | PATH=$PWD/bin "$BASH" "$(plugin_dir)/hooks/pre-tool-use" 2>&1)
  [ -e awk-ran ] || { echo "reader skipped for a mutating command" >&2; return 1; }
  # A wrapper is not read-only even when its command is spelled like one.
  assert_denies "$(bash_event "command rm 'tests/cart total.test.sh'" "$repo")" 'is a pinned test'
}

test_denies_sort_awk_uniq_writes_to_pinned_test() {
  local repo r t cmd
  repo=$(pinned_repo)
  r=$(pin_reason 'tests/cart total.test.sh')
  t="'tests/cart total.test.sh'"
  for cmd in "sort -o $t src/cart.sh" "sort -o$t src/cart.sh" "sort -no $t src/cart.sh" \
    "sort --output=$t src/cart.sh" "sort --output $t src/cart.sh" "ls && sort -o $t src/cart.sh" \
    "cd . && sort -o $t src/cart.sh" "awk -i inplace '{print}' $t" "gawk -iinplace '{print}' $t" \
    "awk --include=inplace -v x=1 '{print}' $t" "uniq src/cart.sh $t" "uniq -c src/cart.sh $t"; do
    assert_denies "$(bash_event "$cmd" "$repo")" "$r"
  done
  # Reading them is fine.
  for cmd in "sort $t" "sort -t, -k2 $t -o out.txt" "awk '{print}' $t" "awk -f prog.awk $t" "uniq $t" "uniq -c $t out.txt"; do
    assert_allows "$(bash_event "$cmd" "$repo")"
  done
}

test_denies_sed_i_on_pinned_test() {
  local repo r w
  repo=$(pinned_repo)
  r=$(pin_reason 'tests/cart total.test.sh')
  assert_denies "$(bash_event "sed -i 's/10/11/' 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "sed -i '' -e 's/10/11/' tests/cart\\ total.test.sh" "$repo")" "$r"
  assert_denies "$(bash_event "cd tests && sed -Ei.bak 's/10/11/' \"cart total.test.sh\"" "$repo")" "$r"
  assert_denies "$(bash_event "perl -pi -e 's/10/11/' \"$repo/tests/cart total.test.sh\"" /)" "$r"
  assert_denies "$(bash_event "echo ok > 'tests/cart total.test.sh'" "$repo/src/..")" "$r"
  assert_denies "$(bash_event "npm test 2>&1 | tee -a 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "true && rm -rf tests" "$repo")" "$r"
  assert_denies "$(bash_event "rm tests/*.sh" "$repo")" "$r"
  assert_denies "$(bash_event "mv 'tests/cart total.test.sh' /tmp/x" "$repo")" "$r"
  assert_denies "$(bash_event "cp src/cart.sh 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "git checkout HEAD~1 -- 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "git -C src restore '../tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "git rm -q 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "truncate -s 0 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "cat > 'tests/cart total.test.sh' <<'EOF'
assert true
EOF" "$repo")" "$r"
  w=$(odd_name)
  w=${w//\"/\\\"}
  assert_denies "$(bash_event "sed -i s/a/b/ \"$w\"" "$repo")" "$(pin_reason "$(odd_name)")"
  # Reading, running and copying out of a pinned test are fine.
  assert_allows "$(bash_event "sed -n 1p 'tests/cart total.test.sh'" "$repo")"
  assert_allows "$(bash_event "bash 'tests/cart total.test.sh' 2>/dev/null >/dev/null" "$repo")"
  assert_allows "$(bash_event "cp 'tests/cart total.test.sh' /tmp/copy" "$repo")"
  assert_allows "$(bash_event "git commit -m 'never rm tests/cart total.test.sh; echo > tests/x'" "$repo")"
  assert_allows "$(bash_event "cat > notes.txt <<'EOF'
rm -rf tests
EOF" "$repo")"
  assert_allows "$(bash_event "sed -i s/a/b/ src/cart.sh" "$repo")"
}

test_denies_push_to_main_explicit() {
  local repo
  repo=$(main_repo)
  git -C "$repo" checkout -q -b feature
  for cmd in 'git push origin main' 'git push -u origin HEAD:main' 'git push origin +main' \
    'git push origin feature:refs/heads/main' 'npm test && git push origin main' \
    "git push 'origin' \"main\"" 'git -c push.default=current push origin main' \
    'git push --delete origin main' 'git push origin refs/heads/*:refs/heads/*' 'git push --all' \
    'git push origin heads/main' 'git push origin feature:heads/main'; do
    assert_denies "$(bash_event "$cmd" "$repo")" 'main'
  done
  # From a folder above the repository.
  assert_denies "$(bash_event "git -C '${repo##*/}' push origin main" "${repo%/*}")" 'main'
  assert_denies "$(bash_event "cd '${repo##*/}' && git push origin main" "${repo%/*}")" 'main'
  # The origin's own default branch wins over the main/master fallback.
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
  assert_denies "$(bash_event 'git push origin trunk' "$repo")" 'trunk'
  assert_allows "$(bash_event 'git push origin main' "$repo")"
  git -C "$repo" symbolic-ref --delete refs/remotes/origin/HEAD
  assert_denies "$(bash_event 'git push origin master' "$repo")" 'master'
}

test_denies_bare_push_on_main() {
  local repo wt
  repo=$(main_repo)
  assert_denies "$(bash_event 'git push' "$repo")" 'main'
  assert_denies "$(bash_event 'git push -u origin' "$repo")" 'main'
  assert_denies "$(bash_event 'git push origin HEAD' "$repo")" 'main'
  # A linked worktree on a feature branch: .git is a file, HEAD lives in its gitdir.
  wt=$PWD/wt
  git -C "$repo" worktree add -q -b feature "$wt"
  [ -f "$wt/.git" ] || { echo "worktree .git is not a file" >&2; return 1; }
  assert_allows "$(bash_event 'git push' "$wt")"
  assert_allows "$(bash_event 'git push -u origin HEAD' "$wt")"
  assert_denies "$(bash_event 'git push origin main' "$wt")" 'main'
}

test_denies_force_push_to_default() {
  local repo
  repo=$(main_repo)
  assert_denies "$(bash_event 'git push -f' "$repo")" 'main'
  assert_denies "$(bash_event 'git push --force-with-lease origin main' "$repo")" 'main'
  assert_denies "$(bash_event 'git push origin +HEAD:main' "$repo")" 'main'
  git -C "$repo" checkout -q -b feature
  # Force-pushing a feature branch is normal after a rebase.
  assert_allows "$(bash_event 'git push --force-with-lease origin feature' "$repo")"
  assert_allows "$(bash_event 'git push -f' "$repo")"
}

test_allows_push_feature_branch() {
  local repo
  repo=$(main_repo)
  git -C "$repo" checkout -q -b feature
  assert_allows "$(bash_event 'git push -u origin feature' "$repo")"
  assert_allows "$(bash_event 'git push' "$repo")"
  assert_allows "$(bash_event 'git push origin main-fix' "$repo")"
  assert_allows "$(bash_event 'git push --dry-run origin main' "$repo")"
  assert_allows "$(bash_event 'git push origin --tags' "$repo")"
  assert_allows "$(bash_event "echo 'git push origin main'" "$repo")"
  assert_allows "$(bash_event "git commit -m 'push to main later'" "$repo")"
}

test_marks_session_changed() {
  local repo m
  repo=$(main_repo)
  m=$repo/.overdrive/run/markers
  assert_allows "$(file_event Edit "$repo/src/a.ts" "$repo" 'sess-A')"
  [ -f "$m/sess-A.changed" ] || { echo "edit not marked" >&2; return 1; }
  # The runtime folder ignores itself, so markers never show in git status.
  assert_eq '' "$(git -C "$repo" status --porcelain)"
  assert_allows "$(bash_event 'git status && ls -la | grep x' "$repo" 'sess-B')"
  [ ! -e "$m/sess-B.changed" ] || { echo "read-only command marked" >&2; return 1; }
  assert_allows "$(bash_event 'cat a 2>/dev/null >/dev/null; grep -r x . 2>&1' "$repo" 'sess-B')"
  [ ! -e "$m/sess-B.changed" ] || { echo "read-only command marked" >&2; return 1; }
  assert_allows "$(bash_event 'npm run format' "$repo" 'sess-B')"
  [ -f "$m/sess-B.changed" ] || { echo "mutating command not marked" >&2; return 1; }
  # Only file tools leave the edit note; a shell command is judged by status and refs.
  [ ! -e "$m/sess-B.edited" ] || { echo "shell command noted as a file edit" >&2; return 1; }
  assert_allows "$(file_event Write "$repo/.env" "$repo" 'sess-B')"
  [ -f "$m/sess-B.edited" ] || { echo "file tool after a shell command not noted" >&2; return 1; }
  assert_allows "$(bash_event 'echo hi > out.txt' "$repo" 'sess-C')"
  [ -f "$m/sess-C.changed" ] || { echo "redirect not marked" >&2; return 1; }
  # A session id cannot write outside the markers folder.
  assert_allows "$(file_event Edit "$repo/src/a.ts" "$repo" '../../x')"
  [ ! -e "$repo/.overdrive/x.changed" ] || { echo "session id escaped" >&2; return 1; }
  # A denied edit changes nothing, so it does not mark.
  repo=$(pinned_repo)
  assert_denies "$(file_event Edit "$repo/tests/cart total.test.sh" "$repo" 'sess-D')" 'pinned'
  [ ! -e "$repo/.overdrive/run/markers/sess-D.changed" ] || { echo "denied edit marked" >&2; return 1; }
}

test_marks_repos_reached_by_cd_and_git_c() {
  local top r inner m
  # The session sits in a folder above the repository, as Reranker sessions do.
  top=$PWD/top
  mkdir -p "$top"
  r=$(main_repo)
  mv "$r" "$top/r"
  r=$top/r
  commit_file "$r" src/a.sh 'a'
  assert_allows "$(bash_event 'cd r && sed -i.bak s/a/b/ src/a.sh' "$top" 'cd-sed')"
  [ -f "$r/.overdrive/run/markers/cd-sed.changed" ] || { echo "cd target not marked" >&2; return 1; }
  assert_allows "$(bash_event 'git -C r commit -qam x' "$top" 'git-c')"
  [ -f "$r/.overdrive/run/markers/git-c.changed" ] || { echo "git -C target not marked" >&2; return 1; }
  assert_allows "$(bash_event 'pushd r/src && npm run build' "$top" 'pushd')"
  [ -f "$r/.overdrive/run/markers/pushd.changed" ] || { echo "pushd target not marked" >&2; return 1; }
  assert_allows "$(bash_event 'cd r && git status' "$top" 'ro')"
  [ ! -e "$r/.overdrive/run/markers/ro.changed" ] || { echo "read-only command marked" >&2; return 1; }
  # A repository nested in another, reached with cd from the outer one.
  inner=$r/vendor/inner
  mkdir -p "$r/vendor"
  git init -q "$inner"
  assert_allows "$(bash_event 'cd vendor/inner && make' "$r" 'nested')"
  m=.overdrive/run/markers/nested.changed
  [ -f "$inner/$m" ] || { echo "nested repo not marked" >&2; return 1; }
  [ -f "$r/$m" ] || { echo "outer repo not marked" >&2; return 1; }
}

test_tokenizer_follows_wrappers_subshells_and_nested_shells() {
  local repo r
  repo=$(pinned_repo)
  r=$(pin_reason 'tests/cart total.test.sh')
  commit_file "$repo" p.sh 'x'
  # Options that are not -i: perl modules and include paths.
  assert_allows "$(bash_event "perl -Mstrict -MList::Util=sum -Ilib -e 'print 1' 'tests/cart total.test.sh'" "$repo")"
  assert_allows "$(bash_event "sed -n -e 's/i/x/p' -f script.sed 'tests/cart total.test.sh'" "$repo")"
  assert_denies "$(bash_event "perl -0777 -pi.bak -e 's/a/b/' 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "sed -nEi 's/a/b/' 'tests/cart total.test.sh'" "$repo")" "$r"
  for cmd in "nice -n 5 rm 'tests/cart total.test.sh'" "timeout -s KILL 30 rm 'tests/cart total.test.sh'" \
    "stdbuf -o L tee 'tests/cart total.test.sh'" "env -u X A=1 rm 'tests/cart total.test.sh'" \
    "command rm 'tests/cart total.test.sh'" "exec rm 'tests/cart total.test.sh'" \
    "pushd tests && rm 'cart total.test.sh'" "bash -c \"rm 'tests/cart total.test.sh'\"" \
    "sh -ec 'cd tests && echo x > \"cart total.test.sh\"'" "eval rm \"'tests/cart total.test.sh'\""; do
    assert_denies "$(bash_event "$cmd" "$repo")" "$r"
  done
  # A subshell's cd ends with the subshell.
  assert_allows "$(bash_event '(cd tests && ls); rm p.sh' "$repo")"
  assert_denies "$(bash_event "(cd src); rm 'tests/cart total.test.sh'" "$repo")" "$r"
  assert_denies "$(bash_event "echo \$(cd src && pwd); rm 'tests/cart total.test.sh'" "$repo")" "$r"
}

test_denies_branch_switch_while_pinned() {
  local repo
  repo=$(pinned_repo)
  git -C "$repo" branch other
  for cmd in 'git switch other' 'git switch -c next' 'git checkout other' 'git checkout -b next' \
    'git -C src checkout other' 'git checkout -' 'git switch -'; do
    assert_denies "$(bash_event "$cmd" "$repo")" 'overdrive pin --release "<reason>"'
  done
  # Restoring a file that is not pinned is not a switch.
  assert_allows "$(bash_event 'git checkout src/cart.sh' "$repo")"
  assert_allows "$(bash_event 'git checkout -- src/cart.sh' "$repo")"
  # Without pins, switching is free.
  repo=$(main_repo)
  git -C "$repo" branch other
  assert_allows "$(bash_event 'git switch other' "$repo")"
  assert_allows "$(bash_event 'git checkout other' "$repo")"
}

test_denies_removing_the_root_while_pinned() {
  local repo r
  repo=$(pinned_repo)
  r=$(pin_reason 'tests/cart total.test.sh')
  assert_denies "$(bash_event 'rm -rf /' "$repo")" "$r"
  assert_denies "$(bash_event 'rm -rf /*' "$repo")" "$r"
  assert_denies "$(bash_event 'rm -rf ..' "$repo/src")" "$r"
}

# p95_us N COMMAND...: best p95 in microseconds over three batches of N runs.
p95_us() {
  local n=$1 b _ t0 t1 times p95 best=''
  shift
  for b in 1 2 3; do
    times=''
    for _ in $(seq "$n"); do
      t0=${EPOCHREALTIME/[.,]/}
      "$@"
      t1=${EPOCHREALTIME/[.,]/}
      times="$times$((t1 - t0))
"
    done
    p95=$(printf '%s' "$times" | sort -n | sed -n "$(((n * 95 + 99) / 100))p")
    echo "batch $b p95: ${p95} us" >&2
    if [ -z "$best" ] || [ "$p95" -lt "$best" ]; then best=$p95; fi
  done
  printf '%s\n' "$best"
}

latency_skipped() {
  # A shared developer machine is too noisy for a wall-clock budget.
  if [ -z "${CI:-}" ] || [ "$(uname -s)" != Linux ]; then
    echo "notice: latency budget is asserted on Linux CI only; skipped"
    return 0
  fi
  if [ -z "${EPOCHREALTIME:-}" ]; then
    echo "notice: bash $BASH_VERSION has no EPOCHREALTIME; latency skipped"
    return 0
  fi
  return 1
}

# run_pair EDIT BASH: one file-tool call and one Bash call, as a session alternates them.
_k=0
run_alternating() {
  _k=$((_k + 1))
  if [ $((_k % 2)) -eq 0 ]; then
    CLAUDE_PLUGIN_ROOT=$_root "$_root/hooks/pre-tool-use" <<<"$1" >/dev/null
  else
    CLAUDE_PLUGIN_ROOT=$_root "$_root/hooks/pre-tool-use" <<<"$2" >/dev/null
  fi
}

test_latency_p95_under_15ms_without_pins() {
  local repo best
  latency_skipped && return 0
  repo=$(main_repo)
  _root=$(plugin_dir)
  run_alternating "$(file_event Edit "$repo/src/a.ts" "$repo")" "$(bash_event 'npm test' "$repo")"
  best=$(p95_us 50 run_alternating "$(file_event Edit "$repo/src/a.ts" "$repo")" "$(bash_event 'npm test' "$repo")")
  [ "$best" -lt 15000 ] || { echo "best p95 ${best} us over 15 ms" >&2; return 1; }
}

test_latency_p95_under_30ms_with_pins() {
  local repo best
  latency_skipped && return 0
  repo=$(pinned_repo)
  _root=$(plugin_dir)
  run_alternating "$(file_event Edit "$repo/src/cart.sh" "$repo")" "$(bash_event 'rm -f build/out.txt && npm test > log.txt' "$repo")"
  best=$(p95_us 50 run_alternating "$(file_event Edit "$repo/src/cart.sh" "$repo")" \
    "$(bash_event 'rm -f build/out.txt && npm test > log.txt' "$repo")")
  [ "$best" -lt 30000 ] || { echo "best p95 ${best} us over 30 ms" >&2; return 1; }
}

# assert_auto_allows EVENT: the hook approves the call so no permission prompt appears.
assert_auto_allows() {
  local out rc=0
  out=$(guard "$1") || rc=$?
  assert_eq 0 "$rc" "exit code"
  assert_eq '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Overdrive read-only command"}}' "$out"
}

# The router's own classification must not cost a permission prompt; nothing else is
# approved, and nothing chained onto the CLI is.
test_allows_the_plugins_read_only_cli_calls() {
  local repo cli
  repo=$(main_repo)
  cli=$(plugin_dir)/bin/overdrive
  assert_auto_allows "$(bash_event "$cli risk --intent 'fix the typo; rm -rf / \$(x) | y' --paths README.md" "$repo")"
  assert_auto_allows "$(bash_event "$cli risk --worktree" "$repo")"
  assert_auto_allows "$(bash_event "\"$cli\" risk --intent \"bump the TTL\" --paths src/auth/session.ts" "$repo")"
  assert_auto_allows "$(bash_event "$cli decisions next-id" "$repo")"
  assert_auto_allows "$(bash_event "$cli decisions check" "$repo")"
  assert_auto_allows "$(bash_event "$cli recall session ttl" "$repo")"
  [ ! -e "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "classification marked" >&2; return 1; }
  # Not approved: other subcommands, other paths, chains, expansions, redirections.
  local c
  for c in "$cli pin src/a.test.ts" "$cli decisions show D-0001x" "$cli evidence red -- npm test" \
    "/tmp/x/bin/overdrive risk --worktree" "overdrive risk --worktree" "$cli risk --worktree; rm -rf src" \
    "$cli risk --worktree && git push" "$cli risk --worktree | tee out" "$cli risk --worktree > out" \
    "$cli risk --intent \"\$(rm -rf src)\"" "$cli risk --intent \`id\`" "$cli risk --paths ~/x" \
    "$cli risk --intent 'unterminated" "$cli risk
rm -rf src" "TMPDIR=/x $cli risk --worktree" "$cli riskier" "$cli risk --paths *"; do
    out=$(guard "$(bash_event "$c" "$repo")")
    case $out in *'"allow"'*) printf 'approved: %s\n' "$c" >&2; return 1 ;; esac
  done
}
