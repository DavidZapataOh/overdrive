#!/usr/bin/env bash
# Tests for plugins/overdrive/bin/overdrive.

plugin_dir() { printf '%s\n' "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive"; }

# fake_plugin DIR: a plugin tree with the real dispatcher and one libexec command.
fake_plugin() {
  mkdir -p "$1/bin" "$1/libexec" "$1/.claude-plugin"
  cp "$(plugin_dir)/bin/overdrive" "$1/bin/overdrive"
  chmod +x "$1/bin/overdrive"
  cat > "$1/libexec/overdrive-echo" <<'CMD'
#!/usr/bin/env bash
printf 'n=%s\n' "$#"
for a in "$@"; do printf 'arg=%s\n' "$a"; done
printf 'home=%s\n' "$OVERDRIVE_HOME"
exit 3
CMD
  printf '{\n  "name": "x",\n  "version": "9.8.7-rc.1",\n  "other": {"version": "no"}\n}\n' > "$1/.claude-plugin/plugin.json"
}

test_unknown_command_exits_64() {
  local rc=0 err
  err=$("$(plugin_dir)/bin/overdrive" nosuchcommand 2>&1 >/dev/null) || rc=$?
  assert_eq 64 "$rc"
  case $err in *nosuchcommand*) ;; *) echo "stderr: $err" >&2; return 1 ;; esac
  case $err in *sage*) ;; *) echo "no usage: $err" >&2; return 1 ;; esac
}

test_no_args_prints_usage_exit_64() {
  local rc=0
  "$(plugin_dir)/bin/overdrive" >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc"
}

test_help_exits_0_on_stdout() {
  local out
  out=$("$(plugin_dir)/bin/overdrive" help)
  case $out in *sage*) ;; *) echo "no usage: $out" >&2; return 1 ;; esac
  "$(plugin_dir)/bin/overdrive" --help > /dev/null
  "$(plugin_dir)/bin/overdrive" -h > /dev/null
}

test_version_reads_plugin_json() {
  local want got
  want=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$(plugin_dir)/.claude-plugin/plugin.json")
  got=$("$(plugin_dir)/bin/overdrive" version)
  assert_eq "$want" "$got"
  [ -n "$got" ]
  fake_plugin "$PWD/fp"
  assert_eq 9.8.7-rc.1 "$("$PWD/fp/bin/overdrive" version)"
}

test_dispatch_passes_args_and_exit_code() {
  fake_plugin "$PWD/fp"
  local out rc=0
  out=$("$PWD/fp/bin/overdrive" echo 'a b' '' "c\"d" 2>&1) || rc=$?
  assert_eq 3 "$rc"
  assert_line "$out" 'n=3'
  assert_line "$out" 'arg=a b'
  assert_line "$out" 'arg='
  assert_line "$out" 'arg=c"d'
  assert_line "$out" "home=$(cd -P "$PWD/fp" && pwd)"
}

test_dispatch_through_symlink() {
  fake_plugin "$PWD/fp"
  mkdir -p "$PWD/links/deeper"
  ln -s "$PWD/fp/bin/overdrive" "$PWD/links/deeper/od" 2>/dev/null || true
  if [ ! -L "$PWD/links/deeper/od" ]; then
    echo "skip: symlinks are not available on this platform"
    return 0
  fi
  local out rc=0
  out=$("$PWD/links/deeper/od" echo x) || rc=$?
  assert_eq 3 "$rc"
  assert_line "$out" 'arg=x'
  assert_eq 9.8.7-rc.1 "$("$PWD/links/deeper/od" version)"
  # Chained and relative links.
  ( cd "$PWD/links" && ln -s deeper/od rel && ./rel version > "$PWD/rel.out" )
  assert_eq 9.8.7-rc.1 "$(cat "$PWD/links/rel.out")"
}

test_dispatch_rejects_path_like_command() {
  fake_plugin "$PWD/fp"
  local rc=0
  "$PWD/fp/bin/overdrive" ../x >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc"
  rc=0
  "$PWD/fp/bin/overdrive" 'a/b' >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc"
}

test_dispatch_works_from_path_with_spaces() {
  fake_plugin "$PWD/my plugin"
  local rc=0
  "$PWD/my plugin/bin/overdrive" echo ok >/dev/null || rc=$?
  assert_eq 3 "$rc"
}
