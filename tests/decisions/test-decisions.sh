#!/usr/bin/env bash
# Tests for overdrive decisions and overdrive recall.

od() { "$BASH" "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" "$@"; }

# entry ID TITLE STATUS [COST]: one well-formed decisions entry.
entry() {
  printf '## %s — %s\n' "$1" "$2"
  printf -- '- Date: 2026-11-06\n'
  printf -- '- Scope: apps/web billing\n'
  printf -- '- Decision: %s applies.\n' "$2"
  printf -- '- Source: "Charge in COP only" — founder, 2026-11-05\n'
  printf -- '- Why: one currency keeps accounting simple.\n'
  [ "${4-x}" = none ] || printf -- '- Cost if wrong: refunds by hand.\n'
  printf -- '- Status: %s\n' "$3"
  printf '\n'
}

header() {
  printf '# Decisions\n'
  printf 'Rules live in: CLAUDE.md files and the project memory index. This file holds rulings only.\n\n'
}

repo_with_log() {
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/.overdrive"
  printf '%s\n' "$repo"
}

test_next_id_increments() {
  local repo
  repo=$(repo_with_log)
  assert_eq D-0001 "$(cd "$repo" && od decisions next-id)"
  { header; entry D-0001 "First" active; entry D-0009 "Ninth" active; entry D-0002 "Second" active; } > "$repo/.overdrive/decisions.md"
  assert_eq D-0010 "$(cd "$repo" && od decisions next-id)"
  assert_eq D-0010 "$(od decisions next-id "$repo/.overdrive/decisions.md")"
}

test_check_accepts_valid_log() {
  local repo
  repo=$(repo_with_log)
  {
    header
    entry D-0001 "Old rule" "superseded by D-0002"
    entry D-0002 "New rule" active
    printf '## D-0003 — Agent call\n- Date: 2026-11-06\n- Scope: ci\n- Decision: Keep it.\n'
    printf -- '- Source: Ruling — builder, 2026-11-06\n- Why: cheap.\n- Cost if wrong: one rerun.\n- Status: active\n'
  } > "$repo/.overdrive/decisions.md"
  (cd "$repo" && od decisions check)
}

test_check_flags_duplicate_id() {
  local repo out rc=0
  repo=$(repo_with_log)
  { header; entry D-0001 "One" active; entry D-0001 "Again" active; } > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od decisions check 2>&1) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" ".overdrive/decisions.md:13: D-0001: duplicate id (first at line 4)"
}

test_check_flags_missing_cost_if_wrong() {
  local repo out rc=0
  repo=$(repo_with_log)
  { header; entry D-0001 "One" active; entry D-0002 "Two" active none; } > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od decisions check 2>&1) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" ".overdrive/decisions.md:13: D-0002: missing field: Cost if wrong"
  assert_no_line "$out" 'D-0001'
}

test_check_flags_dangling_supersede() {
  local repo out rc=0
  repo=$(repo_with_log)
  { header; entry D-0001 "One" "superseded by D-0007"; } > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od decisions check 2>&1) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" ".overdrive/decisions.md:11: D-0001: superseded by missing id D-0007"
}

test_check_flags_unclosed_source_quote() {
  local repo out rc=0
  repo=$(repo_with_log)
  { header; entry D-0001 "One" active; } | sed 's/^- Source: .*/- Source: "Charge in COP only — founder, 2026-11-05/' > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od decisions check 2>&1) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" ".overdrive/decisions.md:8: D-0001: Source quote is not closed"
}

test_check_flags_bad_status_and_date() {
  local repo out rc=0
  repo=$(repo_with_log)
  { header; entry D-0001 "One" maybe; } | sed 's/^- Date: .*/- Date: 6 nov/' > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od decisions check 2>&1) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" ".overdrive/decisions.md:5: D-0001: Date is not YYYY-MM-DD"
  assert_line "$out" ".overdrive/decisions.md:11: D-0001: Status must be active or superseded by D-NNNN"
}

test_show_prints_one_entry() {
  local repo out
  repo=$(repo_with_log)
  { header; entry D-0001 "One" active; entry D-0002 "Two" active; } > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od decisions show D-0002)
  assert_eq "## D-0002 — Two" "$(printf '%s\n' "$out" | sed -n 1p)"
  assert_line "$out" "- Status: active"
  assert_no_line "$out" 'D-0001'
  assert_exit 1 od decisions show D-0005 "$repo/.overdrive/decisions.md"
  assert_exit 64 od decisions show nope "$repo/.overdrive/decisions.md"
}

test_recall_returns_whole_entry() {
  local repo out want
  repo=$(repo_with_log)
  { header; entry D-0001 "Invoices in COP" active; entry D-0002 "Queue names" active; } > "$repo/.overdrive/decisions.md"
  sed -i.bak '13,$ s/Charge in COP only/Use kebab queues/' "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od recall invoices)
  want=$(printf '==> .overdrive/decisions.md <==\n'; entry D-0001 "Invoices in COP" active)
  assert_eq "$want" "$out"
  # Every term must match; matching ignores case.
  out=$(cd "$repo" && od recall INVOICES kebab)
  assert_eq "recall: no match for INVOICES kebab" "$out"
  out=$(cd "$repo" && od recall --any INVOICES kebab)
  assert_line "$out" "## D-0001 — Invoices in COP"
  assert_line "$out" "## D-0002 — Queue names"
}

test_recall_skips_superseded_by_default() {
  local repo out
  repo=$(repo_with_log)
  { header; entry D-0001 "Billing old" "superseded by D-0002"; entry D-0002 "Billing new" active; } > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od recall billing)
  assert_line "$out" "## D-0002 — Billing new"
  assert_no_line "$out" 'D-0001'
  out=$(cd "$repo" && od recall --all billing)
  assert_line "$out" "## D-0001 — Billing old"
  assert_line "$out" "## D-0002 — Billing new"
}

test_recall_searches_learnings_applies_when() {
  local repo out
  repo=$(repo_with_log)
  mkdir -p "$repo/.overdrive/learnings"
  printf -- '---\ntitle: Neon branches\ndate: 2026-11-01\napplies_when: touching Migrations or schema files\narea: data\n---\nRun the branch reset first.\n' > "$repo/.overdrive/learnings/neon.md"
  printf -- '---\ntitle: Fonts\ndate: 2026-11-01\napplies_when: editing the landing\narea: web\n---\nSelf-host fonts.\n' > "$repo/.overdrive/learnings/fonts.md"
  out=$(cd "$repo/.overdrive" && od recall migrations)
  assert_line "$out" "==> .overdrive/learnings/neon.md <=="
  assert_line "$out" "Run the branch reset first."
  assert_line "$out" "applies_when: touching Migrations or schema files"
  assert_no_line "$out" 'fonts'
}

test_recall_no_match_exits_0() {
  local repo out
  repo=$(repo_with_log)
  out=$(cd "$repo" && od recall nothing here)
  assert_eq "recall: no match for nothing here" "$out"
  assert_exit 64 od recall
}

test_check_flags_unclosed_fence() {
  local repo out rc=0
  repo=$(repo_with_log)
  { header; entry D-0001 "One" active; printf '```\nquoted\n\n'; entry D-0002 "Two" active; } |
    sed '/^## D-0002/,$ s/^- Date: .*/- Date: bad/' > "$repo/.overdrive/decisions.md"
  out=$(cd "$repo" && od decisions check 2>&1) || rc=$?
  assert_eq 1 "$rc"
  assert_line "$out" ".overdrive/decisions.md:13: unclosed code fence opened at line 13"
  rc=0
  out=$(cd "$repo" && od recall quoted 2>&1) || rc=$?
  assert_eq 1 "$rc"
  case $out in *"unclosed code fence opened at line 13"*) ;; *) echo "recall: $out" >&2; return 1 ;; esac
  assert_exit 1 od decisions show D-0001 "$repo/.overdrive/decisions.md"
}

test_check_accepts_inner_quotes_in_source() {
  local repo
  repo=$(repo_with_log)
  { header; entry D-0001 "One" active; } |
    sed 's/^- Source: .*/- Source: "he said "no" to it" — me, 2026-01-01/' > "$repo/.overdrive/decisions.md"
  (cd "$repo" && od decisions check)
}

test_next_id_counts_untitled_headings() {
  local repo
  repo=$(repo_with_log)
  { header; printf '## D-0001\n- Date: 2026-11-06\n\n## D-0003 —\n'; } > "$repo/.overdrive/decisions.md"
  assert_eq D-0004 "$(cd "$repo" && od decisions next-id)"
  { header; printf '## D-0001\n'; } > "$repo/.overdrive/decisions.md"
  assert_eq D-0002 "$(cd "$repo" && od decisions next-id)"
}

test_recall_folds_spanish_case_and_accents() {
  local repo out
  repo=$(repo_with_log)
  { header; entry D-0001 "Cancelación del AÑO" active; entry D-0002 "Otra cosa" active; } > "$repo/.overdrive/decisions.md"
  for t in CANCELACIÓN cancelacion Cancelación CANCELACION año AÑO; do
    out=$(cd "$repo" && od recall "$t")
    assert_line "$out" "## D-0001 — Cancelación del AÑO"
    assert_no_line "$out" 'D-0002'
  done
  # Ñ is its own letter: folding never turns it into N.
  assert_eq "recall: no match for ano" "$(cd "$repo" && od recall ano)"
}
