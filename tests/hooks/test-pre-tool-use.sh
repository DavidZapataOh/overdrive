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

# Neither the plugin's own checkout nor a project's runtime folder counts as a change.
test_plugin_root_and_run_dir_are_not_marked() {
  local repo pr
  repo=$(main_repo)
  pr=$(plugin_dir)
  assert_allows "$(bash_event "cd $pr/skills && npm run x" "$pr")"
  [ ! -e "$(dirname "$(dirname "$pr")")/.overdrive/run/markers/sess-1.changed" ] ||
    { echo "plugin checkout marked" >&2; return 1; }
  assert_allows "$(file_event Write "$repo/.overdrive/run/risk-map.proposed" "$repo")"
  [ ! -e "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "run dir write marked" >&2; return 1; }
  assert_allows "$(file_event Write "$repo/src/a.ts" "$repo")"
  [ -f "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "real edit not marked" >&2; return 1; }
}

# A repository that vendors the plugin is still a project: only paths inside the plugin
# directory are the plugin's own.
test_repo_containing_the_plugin_is_still_marked() {
  local repo p
  repo=$(main_repo)
  mkdir -p "$repo/vendor"
  cp -R "$(plugin_dir)" "$repo/vendor/overdrive"
  p=$repo/vendor/overdrive
  printf '%s' "$(file_event Write "$repo/src/auth.ts" "$repo")" |
    CLAUDE_PLUGIN_ROOT=$p CLAUDE_PROJECT_DIR=/nonexistent "$p/hooks/pre-tool-use" >/dev/null
  [ -f "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "edit outside the plugin not marked" >&2; return 1; }
  rm -rf "$repo/.overdrive/run/markers"
  printf '%s' "$(file_event Write "$p/skills/x.md" "$repo")" |
    CLAUDE_PLUGIN_ROOT=$p CLAUDE_PROJECT_DIR=/nonexistent "$p/hooks/pre-tool-use" >/dev/null
  printf '%s' "$(bash_event "cd $p/skills && npm run x" "$p")" |
    CLAUDE_PLUGIN_ROOT=$p CLAUDE_PROJECT_DIR=/nonexistent "$p/hooks/pre-tool-use" >/dev/null
  [ ! -e "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "plugin's own files marked" >&2; return 1; }
  # Leaving the plugin with a trailing `..` lands in the project, which must be marked.
  local outside
  outside=$(mktemp -d)
  printf '%s' "$(bash_event "cd $p && cd .. && rm x" "$outside")" |
    CLAUDE_PLUGIN_ROOT=$p CLAUDE_PROJECT_DIR=/nonexistent "$p/hooks/pre-tool-use" >/dev/null
  rm -rf "$outside"
  [ -f "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "cd .. out of the plugin not marked" >&2; return 1; }
  rm -rf "$repo/.overdrive/run/markers"
  # On Windows, Claude Code spells both the plugin root and the file path the Windows way.
  case $OSTYPE in
    msys* | cygwin*)
      printf '%s' "$(file_event Write "$(cygpath -w "$p/skills/x.md")" "$repo")" |
        CLAUDE_PLUGIN_ROOT=$(cygpath -w "$p") CLAUDE_PROJECT_DIR=/nonexistent "$p/hooks/pre-tool-use" >/dev/null
      [ ! -e "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "Windows-spelled root not matched" >&2; return 1; }
      ;;
  esac
}

# agent_event SUBAGENT [CWD]: a PreToolUse event for an Agent dispatch.
agent_event() {
  printf '{"session_id":"sess-1","transcript_path":"/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"x","subagent_type":"%s","prompt":"review"},"tool_use_id":"toolu_1"}' \
    "$(jstr "${2:-$PWD}")" "$(jstr "$1")"
}

# add_line REPO LINE: add LINE; the review record is what the guard writes, so it goes
# through the internal entry point.
add_line() {
  case $2 in
    Task\ [0-9]*': reviewed by critical-reviewer') (cd "$1" && od ledger _record-review "$(printf '%s' "$2" | tr -dc 0-9)") >/dev/null ;;
    *) (cd "$1" && od ledger add "$2") >/dev/null ;;
  esac
}

# ledger_repo LINE...: a repo with a two-task plan and an active ledger holding LINEs.
ledger_repo() {
  ledger_repo_at "$(make_repo)" "$@"
}

# ledger_repo_at REPO LINE...: the same inside an existing repo, on its current branch.
ledger_repo_at() {
  local repo=$1 line
  shift
  write_file "$repo" docs/plan.md '# Plan

### Task 1: Charges
### Task 2: Refunds'
  (cd "$repo" && od ledger init --plan docs/plan.md) >/dev/null
  for line in "$@"; do
    add_line "$repo" "$line"
  done
  printf '%s\n' "$repo"
}

GATE_TAIL="no critical review after the last change. For each, run '$(plugin_dir)/bin/overdrive' review-package --base <task base> --head HEAD --brief <brief> --lane critical, then dispatch overdrive:critical-reviewer with \"Task <N>\" in its description (the guard records the review when it is dispatched)"

test_denies_final_reviewer_while_a_task_is_unreviewed() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "task 2 has $GATE_TAIL"
  assert_denies "$(agent_event final-reviewer "$repo")" "task 2 has $GATE_TAIL"
  add_line "$repo" 'Task 2: reviewed by critical-reviewer'
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
}

test_denies_final_reviewer_after_the_observed_sequence() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: reviewed by critical-reviewer' 'Task 1: fixing round 1 done, builder reported' 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "tasks 1, 2 have $GATE_TAIL"
}

test_denies_pull_request_while_a_task_is_unreviewed() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' 'Task 1: fixing round 1' 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_denies "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")" "tasks 1, 2 have $GATE_TAIL"
  assert_denies "$(bash_event 'gh pr merge 5 --squash' "$repo")" "tasks 1, 2 have $GATE_TAIL"
  add_line "$repo" 'Task 1: reviewed by critical-reviewer'
  add_line "$repo" 'Task 2: reviewed by critical-reviewer'
  assert_allows "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")"
}

test_allows_pull_request_for_standard_tasks_of_a_mixed_slice() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewed by critical-reviewer' 'Task 1: complete' \
    'Task 2: in-progress' 'Task 2: implemented' 'Task 2: complete' 'Task 3: blocked sudo apt install libfoo')
  assert_allows "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")"
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
}

test_final_reviewer_gates_unmarked_tasks_still_open() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress' 'Task 1: fixing round 1 done' 'Task 2: implemented')
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "tasks 1, 2 have $GATE_TAIL"
  assert_allows "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")"
}

test_allows_gated_calls_without_a_ledger() {
  local repo
  repo=$(make_repo)
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
  assert_allows "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")"
}

test_allows_gated_calls_with_a_ledger_bound_to_another_branch() {
  local repo
  repo=$(make_repo)
  git -C "$repo" checkout -q -b feat-a
  repo=$(ledger_repo_at "$repo" 'Task 1: in-progress critical' 'Task 1: implemented')
  git -C "$repo" checkout -q -b feat-b
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
  assert_allows "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")"
  git -C "$repo" checkout -q feat-a
  assert_denies "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")" "task 1 has $GATE_TAIL"
}

test_denies_a_critical_task_completed_without_a_review() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: complete')
  assert_denies "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")" "task 1 has $GATE_TAIL"
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "task 1 has $GATE_TAIL"
}

test_ledger_started_on_main_gates_on_the_feature_branch_created_after() {
  local repo
  repo=$(ledger_repo)
  git -C "$repo" checkout -q -b feat
  (cd "$repo" && od ledger add 'Task 1: in-progress critical' && od ledger add 'Task 1: implemented') >/dev/null
  assert_denies "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")" "task 1 has $GATE_TAIL"
}

test_unbound_ledger_gates_the_final_review_on_a_feature_branch() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented')
  git -C "$repo" checkout -q -b feat
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "task 1 has $GATE_TAIL"
}

test_pull_request_pattern_needs_the_command_itself() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented')
  assert_allows "$(bash_event 'git commit -m "high priority: create widget"' "$repo")"
  assert_allows "$(bash_event 'grep -rn "gh pr create" docs' "$repo")"
  assert_denies "$(bash_event 'FOO=1 gh --repo a/b pr create --title t' "$repo")" "task 1 has $GATE_TAIL"
  assert_denies "$(bash_event 'cd x && gh pr merge 3 --squash' "$repo")" "task 1 has $GATE_TAIL"
}

# counting_plugin DIR: a copy of the plugin whose ledger command logs each call to DIR/calls.
counting_plugin() {
  mkdir -p "$1/plugin"
  cp -R "$(plugin_dir)/." "$1/plugin/"
  printf '#!/usr/bin/env bash\necho "$*" >> "%s/calls"\n' "$1" > "$1/plugin/libexec/overdrive-ledger"
}

counted_guard() {
  printf '%s' "$2" | CLAUDE_PLUGIN_ROOT="$1/plugin" CLAUDE_PROJECT_DIR=/nonexistent "$1/plugin/hooks/pre-tool-use"
}

test_unrelated_calls_never_read_the_ledger() {
  local repo dir=$PWD/counted
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented')
  counting_plugin "$dir"
  counted_guard "$dir" "$(agent_event overdrive:critical-reviewer "$repo")" >/dev/null
  counted_guard "$dir" "$(agent_event overdrive:builder "$repo")" >/dev/null
  counted_guard "$dir" "$(bash_event 'gh pr view 5' "$repo")" >/dev/null
  counted_guard "$dir" "$(bash_event 'git commit -m "create widget"' "$repo")" >/dev/null
  counted_guard "$dir" "$(bash_event 'ls' "$repo")" >/dev/null
  [ ! -e "$dir/calls" ]
  counted_guard "$dir" "$(bash_event 'gh pr create --title t' "$repo")" >/dev/null
  assert_eq 'unreviewed' "$(cat "$dir/calls")"
}

test_brief_of_a_critical_task_marks_it_so_the_unmarked_sequence_is_denied() {
  local repo
  repo=$(ledger_repo)
  (cd "$repo" && od brief --plan docs/plan.md --task 1 --lane critical && od brief --plan docs/plan.md --task 2 --lane critical) >/dev/null
  # A standard task's brief leaves the ledger alone.
  for line in 'Task 1: in-progress' 'Task 1: reviewing' 'Task 1: fixing round 1 done' 'Task 2: in-progress' 'Task 2: implemented'; do
    (cd "$repo" && od ledger add "$line") >/dev/null
  done
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "tasks 1, 2 have $GATE_TAIL"
  assert_denies "$(bash_event 'gh pr create --title t' "$repo")" "tasks 1, 2 have $GATE_TAIL"
  assert_denies "$(bash_event 'gh pr merge 4 --squash' "$repo")" "tasks 1, 2 have $GATE_TAIL"
}

test_merge_is_gated_from_the_default_branch_and_a_detached_head() {
  local repo
  repo=$(make_repo)
  git -C "$repo" checkout -q -b feat-a
  repo=$(ledger_repo_at "$repo" 'Task 1: in-progress critical' 'Task 1: implemented')
  git -C "$repo" checkout -q -
  assert_allows "$(bash_event 'gh pr create --title t' "$repo")"
  assert_denies "$(bash_event 'gh pr merge 4 --squash' "$repo")" "task 1 has $GATE_TAIL"
  git -C "$repo" checkout -q --detach feat-a
  assert_denies "$(bash_event 'gh pr create --title t' "$repo")" "task 1 has $GATE_TAIL"
}

test_final_review_deny_tells_how_to_close_an_open_standard_task() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress' 'Task 1: implemented')
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "must be marked complete, or critical and reviewed"
}

# dispatch_event SUBAGENT DESCRIPTION PROMPT [CWD]: an Agent dispatch with the given texts.
dispatch_event() {
  printf '{"session_id":"sess-1","transcript_path":"/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"%s","subagent_type":"%s","prompt":"%s"},"tool_use_id":"toolu_1"}' \
    "$(jstr "${4:-$PWD}")" "$(jstr "$2")" "$(jstr "$1")" "$(jstr "$3")"
}

ledger_text() { cat "$(cd "$1" && od ledger path)"; }

test_a_self_written_review_after_a_fix_is_not_a_review() {
  local repo
  repo=$(ledger_repo 'Task 2: in-progress critical' 'Task 2: implemented' 'Task 2: reviewing' 'Task 2: fixing round 1' \
    'Ruling: finding accepted — reviewer evidence — minor' 'Task 2: reviewing' 'Task 2: complete')
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "task 2 has $GATE_TAIL"
  assert_denies "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")" "task 2 has $GATE_TAIL"
}

test_dispatching_the_critical_reviewer_records_the_review() {
  local repo
  repo=$(ledger_repo 'Task 2: in-progress critical' 'Task 2: implemented' 'Task 2: fixing round 1' 'Task 2: complete')
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "task 2 has $GATE_TAIL"
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Re-review Task 2 fix' 'Review the package.' "$repo")"
  assert_eq 1 "$(ledger_text "$repo" | grep -cx 'Task 2: reviewed by critical-reviewer')"
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
  assert_allows "$(bash_event 'gh pr create --base main --title t --body-file b' "$repo")"
}

test_the_task_number_comes_from_the_description_then_the_brief_path() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_allows "$(dispatch_event critical-reviewer 'Critical review Task 1' 'Fixes for Task 2.' "$repo")"
  assert_eq 'Task 1: reviewed by critical-reviewer' "$(ledger_text "$repo" | grep 'reviewed by')"
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Critical review' 'Package for the slice, brief .overdrive/run/plan-123/task-2.md' "$repo")"
  assert_eq 1 "$(ledger_text "$repo" | grep -cx 'Task 2: reviewed by critical-reviewer')"
}

test_the_description_may_name_tasks_in_any_case_list_or_range() {
  local repo desc
  for desc in 'review task 2' 'Review Task #2' 'Critical review Tasks 1-2' 'Critical review Tasks 1, 2' 'Critical review tasks 1 and 2'; do
    repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 2: in-progress critical' 'Task 2: implemented')
    assert_allows "$(dispatch_event overdrive:critical-reviewer "$desc" 'x' "$repo")"
    case $desc in
      *1*) assert_eq 'Task 1: reviewed by critical-reviewer
Task 2: reviewed by critical-reviewer' "$(ledger_text "$repo" | grep 'reviewed by')" "$desc" ;;
      *) assert_eq 'Task 2: reviewed by critical-reviewer' "$(ledger_text "$repo" | grep 'reviewed by')" "$desc" ;;
    esac
  done
}

test_free_prompt_text_never_names_the_reviewed_task() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Critical review' 'Task 2 depends on Task 1; read the package.' "$repo")"
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Slice re-review' 'Findings: .overdrive/run/reviews/task-1-findings.md and task-2-round-1.md' "$repo")"
  assert_eq 0 "$(ledger_text "$repo" | grep -c 'reviewed by')"
}

test_a_critical_review_without_a_task_number_is_allowed_and_records_nothing() {
  local repo
  repo=$(ledger_repo 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Critical lens' 'Review the package.' "$repo")"
  assert_eq 0 "$(ledger_text "$repo" | grep -c 'reviewed by')"
}

test_a_builder_dispatch_records_a_change_and_replays_the_observed_run() {
  local repo
  repo=$(ledger_repo 'Task 2: in-progress critical')
  assert_allows "$(dispatch_event overdrive:builder 'Build Task 2' 'x' "$repo")"
  add_line "$repo" 'Task 2: implemented'
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Critical review Task 2' 'x' "$repo")"
  add_line "$repo" 'Task 2: reviewing'
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
  # The fix round: a builder dispatch with no fixing line, then the controller's own reviewing line.
  assert_allows "$(dispatch_event overdrive:builder 'Fix round 1 Task 2' 'x' "$repo")"
  add_line "$repo" 'Ruling: finding accepted — reviewer evidence — minor'
  add_line "$repo" 'Task 2: reviewing'
  add_line "$repo" 'Task 2: complete'
  assert_eq 2 "$(ledger_text "$repo" | grep -c 'Task 2: changed by builder')"
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "task 2 has $GATE_TAIL"
  assert_denies "$(bash_event 'gh pr create --title t' "$repo")" "task 2 has $GATE_TAIL"
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Re-review Task 2 fix' 'x' "$repo")"
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
}

test_a_closed_run_still_gates_its_own_branch() {
  local repo
  repo=$(make_repo)
  git -C "$repo" checkout -q -b feat-a
  repo=$(ledger_repo_at "$repo" 'Task 1: in-progress critical' 'Task 1: implemented' 'Run: closed — abandoned')
  assert_denies "$(bash_event 'gh pr create --title t' "$repo")" "task 1 has $GATE_TAIL"
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "task 1 has $GATE_TAIL"
  git -C "$repo" checkout -q -b feat-b
  assert_allows "$(bash_event 'gh pr create --title t' "$repo")"
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
}

test_a_closed_unbound_run_frees_every_branch() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented' 'Run: closed — abandoned')
  assert_allows "$(bash_event 'gh pr create --title t' "$repo")"
  assert_allows "$(agent_event overdrive:final-reviewer "$repo")"
}

test_the_deny_text_does_not_offer_closing_the_run() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical' 'Task 1: implemented')
  assert_denies "$(bash_event 'gh pr create --title t' "$repo")" "(the guard records the review when it is dispatched)."
  assert_not_denies_with "$(bash_event 'gh pr create --title t' "$repo")" "abandoned"
}

# assert_not_denies_with EVENT TEXT: the deny reason does not contain TEXT.
assert_not_denies_with() {
  case $(guard "$1") in *"$2"*) printf 'unexpected text: %s\n' "$2" >&2; return 1 ;; esac
}

test_the_final_review_deny_reads_cleanly() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress' 'Task 1: implemented')
  assert_denies "$(agent_event overdrive:final-reviewer "$repo")" "dispatched). A standard or direct task still open at the end of the slice must be marked complete, or critical and reviewed."
}

test_file_tools_cannot_write_the_ledger() {
  local repo
  repo=$(ledger_repo 'Task 1: in-progress critical')
  assert_denies "$(file_event Edit "$(cd "$repo" && od ledger path)" "$repo")" "overdrive ledger add"
  assert_denies "$(file_event Write "$repo/.overdrive/run/active-ledger" "$repo")" "overdrive ledger add"
  assert_allows "$(file_event Write "$repo/.overdrive/run/reviews/x.md" "$repo")"
}

# shellcheck disable=SC2016
test_the_internal_records_cannot_be_called_from_the_shell() {
  local repo
  repo=$(ledger_repo 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_denies "$(bash_event "'$(plugin_dir)/bin/overdrive' ledger _record-review 2" "$repo")" "written by the guard"
  assert_denies "$(bash_event "bash $(plugin_dir)/libexec/overdrive-ledger _record-review 2" "$repo")" "written by the guard"
  assert_denies "$(bash_event "bash \"$(plugin_dir)/libexec/overdrive-ledger\" _record-change 2" "$repo")" "written by the guard"
  assert_denies "$(bash_event "cd x && overdrive ledger --plan p.md _record-review 2" "$repo")" "written by the guard"
  assert_denies "$(bash_event 'OD=/p/bin/overdrive; $OD ledger _record-review 1' "$repo")" "written by the guard"
  assert_denies "$(bash_event 'rg "_record-review"; $OD ledger _record-review 1' "$repo")" "written by the guard"
  assert_allows "$(bash_event 'grep -rn "_record-review" docs' "$repo")"
  assert_allows "$(bash_event 'rg "overdrive ledger _record-review" docs' "$repo")"
  assert_allows "$(bash_event 'git commit -m "guard calls ledger _record-review itself"' "$repo")"
}

test_the_critical_reviewer_dispatch_records_nothing_without_an_applicable_ledger() {
  local repo
  repo=$(make_repo)
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Critical review Task 2' 'x' "$repo")"
  repo=$(ledger_repo 'Task 2: in-progress critical' 'Task 2: implemented' 'Run: closed — abandoned')
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Critical review Task 2' 'x' "$repo")"
  assert_eq 0 "$(ledger_text "$repo" | grep -c 'reviewed by')"
  repo=$(make_repo)
  git -C "$repo" checkout -q -b feat-a
  repo=$(ledger_repo_at "$repo" 'Task 2: in-progress critical' 'Task 2: implemented')
  git -C "$repo" checkout -q -b feat-b
  assert_allows "$(dispatch_event overdrive:critical-reviewer 'Critical review Task 2' 'x' "$repo")"
  assert_eq 0 "$(ledger_text "$repo" | grep -c 'reviewed by')"
}

test_other_agents_never_write_a_review_record() {
  local repo
  repo=$(ledger_repo 'Task 2: in-progress critical' 'Task 2: implemented')
  assert_allows "$(dispatch_event overdrive:reviewer 'Review Task 2' 'x' "$repo")"
  assert_allows "$(dispatch_event overdrive:builder 'Build Task 2' 'x' "$repo")"
  assert_eq 0 "$(ledger_text "$repo" | grep -c 'reviewed by')"
}

# tool_event TOOL INPUT_JSON [CWD]: a PreToolUse event for any tool.
tool_event() {
  printf '{"session_id":"sess-1","transcript_path":"/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s,"tool_use_id":"toolu_1"}' \
    "$(jstr "${3:-$PWD}")" "$1" "$2"
}

# refuse_allow EVENT COMMAND: fails when the hook approves the call.
refuse_allow() {
  local out
  out=$(guard "$1")
  case $out in *'"allow"'*) printf 'approved: %s\n' "$2" >&2; return 1 ;; esac
}

# The router tells the model to set R to the plugin root and call R/bin/overdrive, so the
# expanded form is what a session actually runs.
test_allows_the_read_only_cli_through_a_root_variable() {
  local repo root c
  repo=$(main_repo)
  root=$(plugin_dir)
  assert_auto_allows "$(bash_event "R=$root; \$R/bin/overdrive risk --intent 'Fix the typo in README.md' --paths README.md" "$repo")"
  assert_auto_allows "$(bash_event "R=$root; \"\$R\"/bin/overdrive risk --worktree" "$repo")"
  assert_auto_allows "$(bash_event "R=\"$root\"; \"\${R}/bin/overdrive\" decisions next-id" "$repo")"
  assert_auto_allows "$(bash_event "R='$root'; \${R}/bin/overdrive decisions check" "$repo")"
  assert_auto_allows "$(bash_event "PLUGIN_ROOT=$root && \"\$PLUGIN_ROOT/bin/overdrive\" recall session ttl" "$repo")"
  assert_auto_allows "$(bash_event "R=$root ; \$R/bin/overdrive risk" "$repo")"
  [ ! -e "$repo/.overdrive/run/markers/sess-1.changed" ] || { echo "classification marked" >&2; return 1; }
  for c in "R=/tmp/x; \$R/bin/overdrive risk --worktree" "R=$root/; \$R/bin/overdrive risk" \
    "R=$root/../overdrive; \$R/bin/overdrive risk" "R=${root}x; \$R/bin/overdrive risk" \
    "R=$root; \$R/bin/overdrive pin src/a.test.ts" "R=$root; \$R/bin/overdrive evidence red -- npm test" \
    "R=$root; R2=$root; \$R/bin/overdrive risk" "R=$root; \$R/bin/overdrive risk; rm -rf src" \
    "R=$root; \$R/bin/overdrive risk && git push" "R=$root; \$R/bin/overdrive risk | tee out" \
    "R=$root; \$R/bin/overdrive risk > out" "R=$root; \$R/bin/overdrive risk --paths \$HOME" \
    "R=$root; \$R/bin/overdrive risk --paths \"\$X\"" "R=$root; \$R/bin/overdrive risk --paths *" \
    "R=\$(id); \$R/bin/overdrive risk" "R=$root\$(id); \$R/bin/overdrive risk" \
    "R=$root; \$Q/bin/overdrive risk" "R=$root; \$R/bin/overdrive-x risk" "R=$root; \$R/bin/other risk" \
    "R=$root \$R/bin/overdrive risk" "R=$root; cd src; \$R/bin/overdrive risk" \
    "TMPDIR=$root; \$TMPDIR/bin/overdrive risk" "GOROOT=$root; \$GOROOT/bin/overdrive risk" "DOTNET_ROOT=$root; \$DOTNET_ROOT/bin/overdrive risk" "r=$root; \$r/bin/overdrive risk" "ROOTS=$root; \$ROOTS/bin/overdrive risk" "IFS=$root; \$IFS/bin/overdrive risk" "PATH=$root; \$PATH/bin/overdrive risk" \
    "R=$root; \$R/bin/overdrive risk
rm -rf src" "R=$root; \${R:-x}/bin/overdrive risk" "R=$root; \${R/a/b}/bin/overdrive risk" \
    "R=\"$root\"x; \$R/bin/overdrive risk" "export R=$root; \$R/bin/overdrive risk"; do
    refuse_allow "$(bash_event "$c" "$repo")" "$c" || return 1
  done
}

test_a_root_variable_with_a_special_path_is_allowed_only_when_quoted() {
  local base root repo
  base=$(mktemp -d)
  root="$base/plug in"
  mkdir -p "$root"
  cp -R "$(plugin_dir)/hooks" "$(plugin_dir)/lib" "$root/"
  repo=$(main_repo)
  out=$(printf '%s' "$(bash_event "R=\"$root\"; \"\$R\"/bin/overdrive risk" "$repo")" | CLAUDE_PLUGIN_ROOT=$root "$root/hooks/pre-tool-use")
  case $out in *'"allow"'*) ;; *) echo "quoted form not allowed: $out" >&2; return 1 ;; esac
  out=$(printf '%s' "$(bash_event "R=$root; \$R/bin/overdrive risk" "$repo")" | CLAUDE_PLUGIN_ROOT=$root "$root/hooks/pre-tool-use")
  case $out in *'"allow"'*) echo "unquoted form allowed: $out" >&2; return 1 ;; esac
}

skill_event() { tool_event Skill "{\"skill\":\"$(jstr "$1")\"}"; }

# Approving a skill would also grant its allowed-tools for the turn.
test_skills_get_no_decision() {
  local s
  for s in "$(plugin_dir)"/skills/*/; do
    s=${s%/}
    assert_allows "$(skill_event "overdrive:${s##*/}")"
  done
  assert_allows "$(skill_event overdrive:release-gates)"
}

test_other_skills_get_no_decision() {
  local s
  for s in other:risk-triage risk-triage overdrive:nope overdrive: overdrive:../x overdrive:risk-triage/x \
    'overdrive:risk-triage x' overdrive:.. overdrive:. ''; do
    assert_allows "$(skill_event "$s")"
  done
}

# A plugin copy with a skill, a secret beside it and links that point outside it.
link_plugin() {
  local base=$1
  mkdir -p "$base/root/skills/risk-triage" "$base/root/references" "$base/outside"
  cp -R "$(plugin_dir)/hooks" "$(plugin_dir)/lib" "$base/root/"
  printf 'x\n' > "$base/root/skills/risk-triage/SKILL.md"
  printf 'secret\n' > "$base/outside/secret.txt"
  ln -s "$base/outside" "$base/root/references/dir-link"
  ln -s "$base/outside/secret.txt" "$base/root/references/file-link"
  ln -s "$base/root" "$base/root-link"
  # Git Bash copies instead of linking unless native links are enabled; a copy inside the
  # plugin is not the escape these fixtures stand for.
  local l
  for l in "$base/root/references/dir-link" "$base/root/references/file-link" "$base/root-link"; do
    [ -L "$l" ] || rm -rf "$l"
  done
}

guard_at() {
  printf '%s' "$2" | CLAUDE_PLUGIN_ROOT=$1 CLAUDE_PROJECT_DIR=/nonexistent "$1/hooks/pre-tool-use"
}

assert_allowed_at() {
  local out
  out=$(guard_at "$1" "$2")
  case $out in *'"permissionDecision":"allow"'*) ;; *) printf 'not allowed: %s\n  got: %s\n' "$2" "$out" >&2; return 1 ;; esac
}

assert_silent_at() {
  local out
  out=$(guard_at "$1" "$2")
  [ -z "$out" ] || { printf 'decision for: %s\n  got: %s\n' "$2" "$out" >&2; return 1; }
}

test_allows_reading_the_plugins_own_files() {
  local b root cwd
  b=$(mktemp -d)
  link_plugin "$b"
  root=$b/root
  cwd=$(main_repo)
  assert_allowed_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$root/skills/risk-triage/SKILL.md")\"}" "$cwd")"
  assert_allowed_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$root/skills/risk-triage/SKILL.md")\",\"offset\":1,\"limit\":20}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$root/skills/../skills/risk-triage/SKILL.md")\"}" "$cwd")"
  assert_allowed_at "$root" "$(tool_event Read '{"file_path":"skills/risk-triage/SKILL.md"}' "$root")"
  # A symlinked spelling of the root is not the root.
  assert_silent_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$b/root-link/skills/risk-triage/SKILL.md")\"}" "$cwd")"
}

test_glob_and_grep_get_no_decision_even_inside_the_plugin() {
  local b root cwd
  b=$(mktemp -d)
  link_plugin "$b"
  root=$b/root
  cwd=$(main_repo)
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"*.md\",\"path\":\"$(jstr "$root/skills")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"$(jstr "$root/skills/*/SKILL.md")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"\\\\Users\\\\x\\\\*\",\"path\":\"$(jstr "$root")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Grep "{\"pattern\":\"lane\",\"path\":\"$(jstr "$root/skills")\"}" "$cwd")"
}

# Read opens the lexically normalized path, so a link followed by .. must not be trusted.
test_read_checks_the_path_it_opens() {
  local b root cwd
  b=$(mktemp -d)
  link_plugin "$b"
  root=$b/root
  cwd=$(main_repo)
  mkdir -p "$root/sub/deep" "$root/sub/x" "$b/outside/x"
  ln -s "$root/sub/deep" "$root/link1"
  ln -s "$b/outside" "$root/x"
  printf 'in\n' > "$root/sub/x/f"
  printf 'out\n' > "$b/outside/f"
  assert_silent_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$root/link1/../x/f")\"}" "$cwd")"
  assert_allowed_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$root/sub/x/f")\"}" "$cwd")"
  # Opened as written, x/.. leaves through the link; a dot segment is never allowed.
  assert_silent_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$root/x/../sub/x/f")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$root/./sub/x/f")\"}" "$cwd")"
}

test_reading_outside_the_plugin_gets_no_decision() {
  local b root cwd r
  b=$(mktemp -d)
  link_plugin "$b"
  root=$b/root
  cwd=$(main_repo)
  for r in "$b/outside/secret.txt" "$root/../outside/secret.txt" "$root/skills/../../outside/secret.txt" \
    "${root}-evil/x" "$root/references/dir-link/secret.txt" "$root/references/file-link" \
    "$root/references/dir-link" "$root/skills/missing/x.md" "$cwd/README.md" /etc/passwd; do
    assert_silent_at "$root" "$(tool_event Read "{\"file_path\":\"$(jstr "$r")\"}" "$cwd")" || return 1
  done
  assert_silent_at "$root" "$(tool_event Read '{"file_path":"../outside/secret.txt"}' "$root/skills")"
  assert_silent_at "$root" "$(tool_event Read '{"file_path":"README.md"}' "$cwd")"
  assert_silent_at "$root" "$(tool_event Read '{}' "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"*\",\"path\":\"$(jstr "$b/outside")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"*\",\"path\":\"$(jstr "$root/references/dir-link")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"$(jstr "$root/../outside/*")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"$(jstr "$root/skills/../../outside/*")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"$(jstr "$b/outside/*")\",\"path\":\"$(jstr "$root")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Glob "{\"pattern\":\"*.md\"}" "$root")"
  assert_silent_at "$root" "$(tool_event Grep "{\"pattern\":\"x\",\"path\":\"$(jstr "$b/outside")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Grep "{\"pattern\":\"x\",\"path\":\"$(jstr "$root/references/dir-link")\"}" "$cwd")"
  assert_silent_at "$root" "$(tool_event Grep '{"pattern":"x"}' "$root")"
}

# The guard sits on every read now, so an unrelated one must not fork.
test_an_unrelated_read_forks_nothing() {
  local out
  out=$(printf '%s' "$(tool_event Read '{"file_path":"/etc/hostname"}')" | PATH=/nonexistent CLAUDE_PLUGIN_ROOT="$(plugin_dir)" "$BASH" "$(plugin_dir)/hooks/pre-tool-use" 2>&1)
  assert_eq '' "$out"
  out=$(printf '%s' "$(tool_event Grep '{"pattern":"x","path":"/etc"}')" | PATH=/nonexistent CLAUDE_PLUGIN_ROOT="$(plugin_dir)" "$BASH" "$(plugin_dir)/hooks/pre-tool-use" 2>&1)
  assert_eq '' "$out"
  out=$(printf '%s' "$(skill_event other:thing)" | PATH=/nonexistent CLAUDE_PLUGIN_ROOT="$(plugin_dir)" "$BASH" "$(plugin_dir)/hooks/pre-tool-use" 2>&1)
  assert_eq '' "$out"
}

test_latency_p95_under_15ms_for_an_unrelated_read() {
  local best ev
  latency_skipped && return 0
  _root=$(plugin_dir)
  ev=$(tool_event Read '{"file_path":"/home/u/project/src/a.ts"}' /home/u/project)
  best=$(p95_us 50 run_alternating "$ev" "$ev")
  [ "$best" -lt 15000 ] || { echo "best p95 ${best} us over 15 ms" >&2; return 1; }
}

# A root with a quote in its name must never be spliced into a quoted form of the other kind.
# shellcheck disable=SC2016
test_quote_characters_in_the_root_refuse_that_quoting() {
  local base root repo n out name
  repo=$(main_repo)
  base=$(mktemp -d)
  for name in "o'neil" 'dq"x' 'dollar$x' 'back\\slash'; do
    root="$base/$name/overdrive"
    mkdir -p "$root"
    cp -R "$(plugin_dir)/hooks" "$(plugin_dir)/lib" "$root/"
    for n in 1 2 3 4 5 6; do
      case $n in
        1) cmd="R='$root'; \"\$R\"/bin/overdrive risk \"'; touch $base/PWNED; \"'\"\\'" ;;
        2) cmd="'$root/bin/overdrive' risk \"'; touch $base/PWNED; \"'\"\\'" ;;
        3) cmd="R='$root'; \"\$R\"/bin/overdrive risk --worktree" ;;
        4) cmd="R=\"$root\"; \"\$R\"/bin/overdrive risk --worktree" ;;
        5) cmd="'$root/bin/overdrive' risk --worktree" ;;
        6) cmd="\"$root/bin/overdrive\" risk --worktree" ;;
      esac
      out=$(printf '%s' "$(bash_event "$cmd" "$repo")" | CLAUDE_PLUGIN_ROOT=$root "$root/hooks/pre-tool-use")
      case $name:$n:$out in
        "o'neil":1:*'"allow"'* | "o'neil":2:*'"allow"'* | "o'neil":3:*'"allow"'* | "o'neil":5:*'"allow"'*) echo "approved: $cmd" >&2; return 1 ;;
        "o'neil":4:*'"allow"'* | "o'neil":6:*'"allow"'*) ;;
        "o'neil":4:* | "o'neil":6:*) echo "refused safe: $cmd" >&2; return 1 ;;
        'dq"x':4:*'"allow"'* | 'dq"x':6:*'"allow"'* | 'dollar$x':4:*'"allow"'* | 'dollar$x':6:*'"allow"'*) echo "approved: $cmd" >&2; return 1 ;;
        'back\\slash':4:*'"allow"'* | 'back\\slash':6:*'"allow"'*) echo "approved: $cmd" >&2; return 1 ;;
        'dq"x':3:*'"allow"'* | 'dq"x':5:*'"allow"'* | 'dollar$x':3:*'"allow"'* | 'dollar$x':5:*'"allow"'* | 'back\\slash':3:*'"allow"'* | 'back\\slash':5:*'"allow"'*) ;;
        'dq"x':3:* | 'dq"x':5:* | 'dollar$x':3:* | 'dollar$x':5:* | 'back\\slash':3:* | 'back\\slash':5:*) echo "refused safe: $cmd" >&2; return 1 ;;
      esac
    done
  done
  [ ! -e "$base/PWNED" ] || { echo "command ran" >&2; return 1; }
}
