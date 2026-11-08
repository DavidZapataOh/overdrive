#!/usr/bin/env bash
# Tests for overdrive brief.

plugin() { printf '%s\n' "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive"; }
fixtures() { printf '%s\n' "$(dirname "$RUNNER")/brief/fixtures"; }
od() { "$BASH" "$(plugin)/bin/overdrive" "$@"; }

# isolate: never read the real user config.
isolate() {
  unset CLAUDE_CONFIG_DIR CLAUDE_CODE_PROJECT_DIR_NAME
  HOME=$PWD/home
  export HOME
  mkdir -p "$HOME"
}

# nested_repo DIR: a git repository at DIR (parents created).
nested_repo() {
  mkdir -p "$1"
  git init -q "$1"
  git -C "$1" config user.name Test
  git -C "$1" config user.email test@example.com
  git -C "$1" config commit.gpgsign false
  git -C "$1" commit -q --allow-empty -m init
}

# section FILE START END: the lines strictly between two exact lines, outer blank lines trimmed.
section() {
  awk -v s="$2" -v e="$3" '
    $0 == e && on { exit }
    on { buf[++n] = $0 }
    $0 == s { on = 1 }
    END {
      for (a = 1; a <= n && buf[a] == ""; a++) ;
      for (b = n; b >= a && buf[b] == ""; b--) ;
      for (i = a; i <= b; i++) print buf[i]
    }
  ' "$1"
}

# run_dir PLAN: the brief directory for a plan, named after its stem and absolute path.
run_dir() {
  local sum stem
  sum=$(printf '%s' "$1" | cksum)
  stem=$(basename "$1" .md)
  printf '%s-%s\n' "${stem//[!A-Za-z0-9._-]/-}" "${sum%% *}"
}

# slug PATH: the memory directory name for PATH.
slug() { local s=${1//\//-}; printf '%s\n' "${s//./-}"; }

test_brief_extracts_task_verbatim() {
  isolate
  local repo root path want
  repo=$(make_repo)
  root=$(cd "$repo" && pwd)
  path=$(cd "$repo" && od brief --plan "$(fixtures)/plan.md" --task 1 --lane standard)
  assert_eq "$root/.overdrive/run/$(run_dir "$(fixtures)/plan.md")/task-1.md" "$path"
  want=$(sed -n '/^### Task 1:/,/^- \[ \] \*\*Step 1/p' "$(fixtures)/plan.md")
  assert_eq "$want" "$(section "$path" '## Task' '## Global Constraints')"
  # Headings inside fences neither end the task nor start one.
  assert_file_contains "$path" '^### Task 9: not a real task$'
  # Task-per-heading plans in the earlier format work unchanged.
  path=$(cd "$repo" && od brief --plan "$(fixtures)/tdd-plan.md" --task 2 --lane standard)
  assert_eq "$root/.overdrive/run/$(run_dir "$(fixtures)/tdd-plan.md")/task-2.md" "$path"
  want=$(sed -n '/^### Task 2:/,/^- \[ \] \*\*Step 1/p' "$(fixtures)/tdd-plan.md")
  assert_eq "$want" "$(section "$path" '## Task' '## Global Constraints')"
  path=$(cd "$repo" && od brief --plan "$(fixtures)/tdd-plan.md" --task 1 --lane standard)
  assert_file_contains "$path" '^// ### Task 4: inside code$'
  assert_file_contains "$path" '^- \[ \] \*\*Step 2: Commit\*\*$'
  assert_no_line "$(cat "$path")" '^### Task 2'
}

# shellcheck disable=SC2016
test_brief_copies_global_constraints() {
  isolate
  local repo path want
  repo=$(make_repo)
  path=$(cd "$repo" && od brief --plan "$(fixtures)/plan.md" --task 2 --lane standard)
  want=$(printf '%s\n' '- Lanes are exactly `direct`, `standard`, `critical`.' '- Keep the invoices module fast.')
  assert_eq "$want" "$(section "$path" '## Global Constraints' '## Lane')"
  path=$(cd "$repo" && od brief --plan "$(fixtures)/tdd-plan.md" --task 1 --lane standard)
  want=$(printf '%s\n' '- Todo el código en inglés; el texto visible en español.' '- Nada de mocks en código de producto.')
  assert_eq "$want" "$(section "$path" '## Global Constraints' '## Lane')"
}

test_brief_sections_in_order() {
  isolate
  local repo path
  repo=$(make_repo)
  path=$(cd "$repo" && od brief --plan "$(fixtures)/plan.md" --task 2 --lane standard)
  assert_eq "$(printf '%s\n' '# Brief' '## Task' '## Global Constraints' '## Lane' '## Rules' '## Report')" \
    "$(grep -E '^##? (Brief|Task|Global Constraints|Lane|Rules|Report)$' "$path")"
  assert_eq "$(printf '%s\n' 'lane standard' 'note lane set by the caller')" "$(section "$path" '## Lane' '## Rules')"
  assert_file_contains "$path" '^- Status: DONE \| DONE_WITH_CONCERNS \| BLOCKED \| NEEDS_CONTEXT$'
  assert_file_contains "$path" 'at most 15 lines'
  assert_file_contains "$path" 'Ruling: <what> — <why> — <cost if wrong>'
  assert_exit 64 od brief --plan "$(fixtures)/plan.md" --task 2 --lane fast
}

# Agents run the CLI by the absolute path the brief gives: bin/ is not on their PATH.
test_brief_names_the_cli_path() {
  isolate
  local repo path cli
  repo=$(make_repo)
  cli=$(cd "$(plugin)/bin" && pwd -P)/overdrive
  path=$(cd "$repo" && od brief --text 'Fix the footer link' --lane direct)
  assert_eq "Overdrive CLI: $cli" "$(sed -n 3p "$path")"
  path=$(cd "$repo" && od brief --plan "$(fixtures)/plan.md" --task 2 --lane standard)
  assert_eq "Overdrive CLI: $cli" "$(sed -n 3p "$path")"
}

test_brief_lists_claude_md_chain() {
  isolate
  local top repo path rules want
  top=$(cd "$PWD" && pwd)/outer
  repo=$top/repo
  nested_repo "$repo"
  mkdir -p "$HOME/.claude" "$repo/.claude" "$repo/plugins/x/lib" "$repo/.overdrive"
  printf 'user\n' > "$HOME/.claude/CLAUDE.md"
  printf 'outer\n' > "$top/CLAUDE.md"
  printf 'root\n' > "$repo/CLAUDE.md"
  printf 'dot\n' > "$repo/.claude/CLAUDE.md"
  printf 'local\n' > "$repo/CLAUDE.local.md"
  printf 'nested\n' > "$repo/plugins/x/CLAUDE.md"
  printf '# Decisions\n' > "$repo/.overdrive/decisions.md"
  path=$(cd "$repo/plugins" && od brief --plan "$(fixtures)/plan.md" --task 2 --lane standard)
  rules=$(grep -E '^- /' "$path")
  want=$(printf -- '- %s\n' "$HOME/.claude/CLAUDE.md" "$top/CLAUDE.md" "$repo/CLAUDE.md" \
    "$repo/.claude/CLAUDE.md" "$repo/CLAUDE.local.md" "$repo/plugins/x/CLAUDE.md" "$repo/.overdrive/decisions.md")
  assert_eq "$want" "$rules"
  # The config directory replaces ~/.claude for the user file.
  mkdir -p "$PWD/cfg"
  printf 'cfg\n' > "$PWD/cfg/CLAUDE.md"
  path=$(base=$PWD && cd "$repo" && CLAUDE_CONFIG_DIR=$base/cfg od brief --plan "$(fixtures)/plan.md" --task 2 --lane standard)
  assert_line "$(cat "$path")" "- $PWD/cfg/CLAUDE.md"
  assert_no_line "$(cat "$path")" "^- $HOME/.claude/CLAUDE.md$"
}

test_brief_finds_memory_index_above_repo() {
  isolate
  local base project repo mem path
  base=$(cd "$PWD" && pwd)
  project=$base/my.project
  repo=$project/app
  nested_repo "$repo"
  CLAUDE_CONFIG_DIR=$base/cfg
  export CLAUDE_CONFIG_DIR
  mem=$CLAUDE_CONFIG_DIR/projects/$(slug "$project")/memory/MEMORY.md
  mkdir -p "${mem%/*}"
  printf -- '- [Billing](billing.md) — invoices in COP\n' > "$mem"
  path=$(cd "$repo" && od brief --text "Change invoices" --lane direct)
  assert_line "$(cat "$path")" "Memory index: $mem"
  # The nearest index wins once the repository has its own.
  mem=$CLAUDE_CONFIG_DIR/projects/$(slug "$repo")/memory/MEMORY.md
  mkdir -p "${mem%/*}"
  printf -- '- nothing\n' > "$mem"
  path=$(cd "$repo" && od brief --text "Change invoices" --lane direct)
  assert_line "$(cat "$path")" "Memory index: $mem"
  # An explicit project directory name overrides the walk.
  mkdir -p "$CLAUDE_CONFIG_DIR/projects/named/memory"
  printf -- '- named\n' > "$CLAUDE_CONFIG_DIR/projects/named/memory/MEMORY.md"
  path=$(cd "$repo" && CLAUDE_CODE_PROJECT_DIR_NAME=named od brief --text "Change invoices" --lane direct)
  assert_line "$(cat "$path")" "Memory index: $CLAUDE_CONFIG_DIR/projects/named/memory/MEMORY.md"
}

test_brief_finds_memory_index_from_linked_worktree() {
  isolate
  local base repo wt main mem path
  base=$(cd "$PWD" && pwd)
  repo=$base/main
  nested_repo "$repo"
  wt=$base/linked
  git -C "$repo" worktree add -q "$wt" -b side
  CLAUDE_CONFIG_DIR=$base/cfg
  export CLAUDE_CONFIG_DIR
  # Memory is keyed by the path git reports, which is physical (/private/var on macOS,
  # the Windows temp folder under Git Bash), not by the logical path used to get there.
  main=$(cd "$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir)/.." && pwd)
  mem=$CLAUDE_CONFIG_DIR/projects/$(slug "$main")/memory/MEMORY.md
  mkdir -p "${mem%/*}"
  printf -- '- shared\n' > "$mem"
  path=$(cd "$wt" && od brief --text "Change invoices" --lane direct)
  assert_eq "$wt/.overdrive/run/briefs" "${path%/*}"
  assert_line "$(cat "$path")" "Memory index: $mem"
}

test_brief_includes_matching_memory_lines_only() {
  isolate
  local base repo mem path out
  base=$(cd "$PWD" && pwd)
  repo=$base/repo
  nested_repo "$repo"
  CLAUDE_CONFIG_DIR=$base/cfg
  export CLAUDE_CONFIG_DIR
  mem=$CLAUDE_CONFIG_DIR/projects/$(slug "$repo")/memory/MEMORY.md
  mkdir -p "${mem%/*}"
  {
    printf '# Invoices index\n\n'
    printf -- '- [Billing](billing.md) — Invoices are charged in COP\n'
    printf -- '- [Fonts](fonts.md) — self-host the typefaces\n'
    printf -- '- [Glue](glue.md) — that with from para como\n'
    printf -- '- [Short](short.md) — fix the bug now\n'
    printf -- '- [Tasks](tasks.md) — every task file step\n'
    printf -- '- [Días](dias.md) — días hábiles\n'
  } > "$mem"
  path=$(cd "$repo" && od brief --lane direct --text "Fix the bug: invoices that come with from para como. Task step files, días.")
  out=$(cat "$path")
  assert_line "$out" '- [Billing](billing.md) — Invoices are charged in COP'
  assert_line "$out" '- [Días](dias.md) — días hábiles'
  assert_no_line "$out" 'Fonts|Glue|Short|Tasks|^# Invoices index'
}

test_brief_includes_recall_hits() {
  isolate
  local repo path out
  repo=$(make_repo)
  mkdir -p "$repo/.overdrive/learnings"
  printf -- '---\ntitle: Invoice rounding\ndate: 2026-11-01\napplies_when: invoices change\narea: billing\n---\nRound half up.\n' > "$repo/.overdrive/learnings/rounding.md"
  printf -- '---\ntitle: Fonts\ndate: 2026-11-01\napplies_when: landing\narea: web\n---\nSelf-host.\n' > "$repo/.overdrive/learnings/fonts.md"
  path=$(cd "$repo" && od brief --lane direct --text "Change invoices totals")
  out=$(cat "$path")
  assert_line "$out" '==> .overdrive/learnings/rounding.md <=='
  assert_line "$out" 'Round half up.'
  assert_no_line "$out" 'Self-host'
}

test_brief_text_mode() {
  isolate
  local repo root path text sum
  repo=$(make_repo)
  root=$(cd "$repo" && pwd)
  text='Fix the footer link on the landing'
  sum=$(printf '%s' "$text" | cksum | awk '{ print $1 }')
  path=$(cd "$repo" && od brief --text "$text" --lane direct)
  assert_eq "$root/.overdrive/run/briefs/$sum.md" "$path"
  assert_eq "$text" "$(section "$path" '## Task' '## Lane')"
  assert_no_line "$(cat "$path")" '^## Global Constraints$'
  # --out writes elsewhere and still prints the path.
  path=$(base=$PWD && cd "$repo" && od brief --text "$text" --lane direct --out "$base/custom.md")
  assert_eq "$PWD/custom.md" "$path"
  assert_file_contains "$path" '^# Brief$'
}

test_brief_unknown_task_exits_65() {
  isolate
  local repo rc=0 err
  repo=$(make_repo)
  err=$(cd "$repo" && od brief --plan "$(fixtures)/plan.md" --task 9 --lane standard 2>&1 >/dev/null) || rc=$?
  assert_eq 65 "$rc"
  case $err in *"task 9"*) ;; *) echo "stderr: $err" >&2; return 1 ;; esac
  rc=0
  (cd "$repo" && od brief --plan "$(fixtures)/plan.md" --task 4 >/dev/null 2>&1) || rc=$?
  [ "$rc" -ne 65 ]
  assert_exit 64 od brief --task 1
  assert_exit 64 od brief --plan "$(fixtures)/plan.md" --task 1 --text both
  assert_exit 66 od brief --plan "$PWD/missing.md" --task 1
}

# stub_plugin DIR [RISK_BODY]: a copy of the plugin whose risk command is RISK_BODY, or absent.
stub_plugin() {
  mkdir -p "$1"
  cp -R "$(plugin)/." "$1/"
  rm -f "$1/libexec/overdrive-risk"
  if [ -n "${2-}" ]; then printf '%s\n' '#!/usr/bin/env bash' "$2" > "$1/libexec/overdrive-risk"; fi
}

test_brief_lane_from_risk() {
  isolate
  local repo path lane
  repo=$(make_repo)
  # shellcheck disable=SC2016
  stub_plugin "$PWD/p" 'printf "lane standard\n"; for a in "$@"; do printf "note arg %s\n" "$a" | head -n 1; done; printf "Risk: standard — docs\n"'
  path=$(base=$PWD && cd "$repo" && "$BASH" "$base/p/bin/overdrive" brief --plan "$(fixtures)/plan.md" --task 2)
  lane=$(section "$path" '## Lane' '## Rules')
  assert_eq 'lane standard' "$(printf '%s\n' "$lane" | sed -n 1p)"
  assert_line "$lane" 'note arg --intent'
  assert_line "$lane" 'note arg ### Task 2: Brief'
  assert_line "$lane" 'note arg --paths'
  assert_line "$lane" 'note arg plugins/x/lib/common.sh'
  assert_line "$lane" 'note arg docs/a.md'
  assert_line "$lane" 'note arg tests/b/test-b.sh'
  assert_line "$lane" 'Risk: standard — docs'
}

test_brief_lane_fails_closed() {
  isolate
  local repo path want
  repo=$(make_repo)
  stub_plugin "$PWD/none"
  path=$(base=$PWD && cd "$repo" && "$BASH" "$base/none/bin/overdrive" brief --text "Change invoices")
  want=$(printf '%s\n' 'lane critical' 'note classification unavailable: overdrive risk is not installed' 'Risk: critical — classification-failed')
  assert_eq "$want" "$(section "$path" '## Lane' '## Rules')"
  stub_plugin "$PWD/broken" 'echo "bad map" >&2; exit 2'
  path=$(base=$PWD && cd "$repo" && "$BASH" "$base/broken/bin/overdrive" brief --text "Change invoices")
  want=$(printf '%s\n' 'lane critical' 'note classification unavailable: overdrive risk exited 2: bad map' 'Risk: critical — classification-failed')
  assert_eq "$want" "$(section "$path" '## Lane' '## Rules')"
  stub_plugin "$PWD/garbled" 'echo "lane fast"'
  path=$(base=$PWD && cd "$repo" && "$BASH" "$base/garbled/bin/overdrive" brief --text "Change invoices")
  assert_line "$(cat "$path")" 'note classification unavailable: overdrive risk printed no lane'
  # Its own fail-closed exit keeps the classifier output.
  stub_plugin "$PWD/closed" 'printf "lane critical\nitem classification-failed critical failure unborn\nRisk: critical — classification-failed\n"; exit 3'
  path=$(base=$PWD && cd "$repo" && "$BASH" "$base/closed/bin/overdrive" brief --text "Change invoices")
  assert_line "$(cat "$path")" 'item classification-failed critical failure unborn'
}

test_brief_outside_git_fails() {
  isolate
  mkdir plain
  local rc=0
  (cd plain && od brief --text x --lane direct >/dev/null 2>&1) || rc=$?
  assert_eq 1 "$rc"
}

test_brief_same_named_plans_do_not_share_a_dir() {
  isolate
  local repo root phys a b
  repo=$(make_repo)
  root=$(cd "$repo" && pwd)
  # Relative plan paths are made absolute from the physical cwd (od_plan_dir).
  phys=$(cd "$repo" && pwd -P)
  mkdir -p "$repo/one" "$repo/two"
  cp "$(fixtures)/plan.md" "$repo/one/plan.md"
  cp "$(fixtures)/plan.md" "$repo/two/plan.md"
  a=$(cd "$repo" && od brief --plan one/plan.md --task 1 --lane standard)
  b=$(cd "$repo/two" && od brief --plan plan.md --task 1 --lane standard)
  assert_eq "$root/.overdrive/run/$(run_dir "$phys/one/plan.md")/task-1.md" "$a"
  assert_eq "$root/.overdrive/run/$(run_dir "$phys/two/plan.md")/task-1.md" "$b"
  [ "$a" != "$b" ]
}

# shellcheck disable=SC2016
test_brief_unclosed_fence_in_plan_fails() {
  isolate
  local repo rc=0 err
  repo=$(make_repo)
  printf '## Global Constraints\n\n- x\n\n### Task 1: A\n- Create: `a.md`\n\n```\n### Task 2: B\n- Create: `a.md`\n' > "$PWD/broken.md"
  err=$(base=$PWD && cd "$repo" && od brief --plan "$base/broken.md" --task 1 --lane standard 2>&1 >/dev/null) || rc=$?
  assert_eq 65 "$rc"
  case $err in *"unclosed code fence opened at line 8"*) ;; *) echo "stderr: $err" >&2; return 1 ;; esac
  rc=0
  od overlap --plan "$PWD/broken.md" --tasks 1 >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
}

test_brief_memory_matching_folds_accents() {
  isolate
  local base repo mem path out
  base=$(cd "$PWD" && pwd)
  repo=$base/repo
  nested_repo "$repo"
  CLAUDE_CONFIG_DIR=$base/cfg
  export CLAUDE_CONFIG_DIR
  mem=$CLAUDE_CONFIG_DIR/projects/$(slug "$repo")/memory/MEMORY.md
  mkdir -p "${mem%/*}"
  printf -- '- [Cobro](cobro.md) — CANCELACIÓN del plan\n- [Otro](otro.md) — fuentes propias\n' > "$mem"
  path=$(cd "$repo" && od brief --lane direct --text "Revisa la cancelacion")
  out=$(cat "$path")
  assert_line "$out" '- [Cobro](cobro.md) — CANCELACIÓN del plan'
  assert_no_line "$out" 'fuentes'
}
