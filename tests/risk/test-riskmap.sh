#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Tests for plugins/overdrive/lib/riskmap.sh and lib/floors.conf.

lib_dir() { printf '%s/plugins/overdrive/lib\n' "$(dirname "$(dirname "$RUNNER")")"; }

load() { . "$(lib_dir)/riskmap.sh"; riskmap_load "$@"; }

tab=$(printf '\t')

# rec KIND PATTERN ITEM LANE LINE: the normalized record for map.conf.
rec() { printf '%s\t%s\t%s\t%s\tmap.conf:%s' "$1" "$2" "$3" "$4" "$5"; }

# rejects TEXT REASON: map.conf holding TEXT fails with exit 65 and exactly REASON.
rejects() {
  printf '%s\n' "$1" > map.conf
  rc=0
  load map.conf > out 2> err || rc=$?
  assert_eq 65 "$rc" "exit code"
  assert_eq "invalid rule at map.conf:1: $2" "$(cat err)"
  assert_eq "" "$(cat out)" "no records on error"
}

test_parses_all_kinds() {
  cat > map.conf <<'EOF'
path apps/**/billing/** money standard
pathtoken Ledger money
keyword "Refund Policy" money
symbol chargeCustomer money critical
content stripe\.charges\.create money
EOF
  out=$(load map.conf)
  assert_eq "$(rec path 'apps/**/billing/**' money standard 1)
$(rec pathtoken ledger money critical 2)
$(rec keyword 'refund policy' money critical 3)
$(rec symbol chargeCustomer money critical 4)
$(rec content 'stripe\.charges\.create' money critical 5)" "$out"
}

test_quoted_pattern_with_spaces() {
  printf '%s\n' 'path "apps/web/src/app/páginas legales/**" legal-copy standard' > map.conf
  out=$(load map.conf)
  assert_eq "$(rec path 'apps/web/src/app/páginas legales/**' legal-copy standard 1)" "$out"
}

test_quoted_pattern_escapes() {
  printf '%s\n' 'path "say \"hi\" \\ \d" greeting' 'content a"b"c quotes' > map.conf
  out=$(load map.conf)
  assert_line "$out" "$(rec path 'say "hi" \ \d' greeting critical 1)"
  assert_line "$out" "$(rec content 'a"b"c' quotes critical 2)"
}

test_default_lane_is_critical() {
  printf 'path src/** core\n' > map.conf
  assert_eq "$(rec path 'src/**' core critical 1)" "$(load map.conf)"
}

test_comments_and_blank_lines_ignored() {
  printf '# header\n\n   \t\n  # indented\npath src/** core standard # trailing\npath "#tag/**" tag\n' > map.conf
  out=$(load map.conf)
  assert_eq "$(rec path 'src/**' core standard 5)
$(rec path '#tag/**' tag critical 6)" "$out"
}

test_crlf_line_endings() {
  printf 'path a/** one\r\n\r\n# note\r\nkeyword "two words" two standard\r\n' > map.conf
  out=$(load map.conf)
  assert_eq "$(rec path 'a/**' one critical 1)
$(rec keyword 'two words' two standard 4)" "$out"
}

test_bom_at_file_start() {
  printf '\357\273\277path a/** one\n' > map.conf
  assert_eq "$(rec path 'a/**' one critical 1)" "$(load map.conf)"
}

test_last_line_without_newline() {
  printf 'path a/** one\npath b/** two' > map.conf
  assert_line "$(load map.conf)" "$(rec path 'b/**' two critical 2)"
}

test_empty_map_has_no_records() {
  : > map.conf
  out=$(load map.conf)
  assert_eq "" "$out"
}

test_unknown_kind_is_invalid() {
  rejects 'file src/** core' "unknown kind 'file' (path, pathtoken, keyword, symbol or content)"
}

test_unknown_lane_is_invalid() {
  rejects 'path src/** core direct' "unknown lane 'direct' (critical or standard)"
}

test_bad_item_name_is_invalid() {
  rejects 'path src/** Core_Item' "invalid item 'Core_Item' (lowercase letters and digits joined by single hyphens)"
  rejects 'path src/** core-' "invalid item 'core-' (lowercase letters and digits joined by single hyphens)"
  rejects 'path src/** a--b' "invalid item 'a--b' (lowercase letters and digits joined by single hyphens)"
}

test_missing_fields_are_invalid() {
  rejects 'path' "missing pattern"
  rejects 'path src/**' "missing item"
  rejects 'path src/** core critical extra' "unexpected field 'extra'"
}

test_quote_errors_are_invalid() {
  rejects 'path "src/** core' "unterminated quote"
  rejects 'path "src"x core' "unexpected character after closing quote"
  rejects 'path "" core' "empty pattern"
}

test_tab_inside_pattern_is_invalid() {
  rejects "path \"a${tab}b\" core" "pattern contains a tab"
}

test_kind_specific_checks() {
  rejects 'path /src/** core' "path glob must be relative to the repository root"
  rejects 'pathtoken auth-z auth' "path token cannot contain / . _ - or spaces"
  rejects 'keyword "drop-table" data' "keyword must be words of letters, digits and underscores"
  rejects 'symbol foo.bar data' "symbol must be an identifier"
}

test_keyword_collapses_spaces_and_lowercases() {
  rejects "keyword \"Row${tab}Level\" tenant" "pattern contains a tab"
  printf 'keyword "  Row   Level  Security " tenant\n' > map.conf
  assert_eq "$(rec keyword 'row level security' tenant critical 1)" "$(load map.conf)"
}

test_content_intervals_are_expanded() {
  printf '%s\n' 'content AKIA[0-9]{3} a' 'content x(ab){2,} b' 'content "y[^}]{1,3}z" c' 'content q{0}r d' 'content a{x}\{ e' > map.conf
  out=$(load map.conf)
  assert_line "$out" "$(rec content 'AKIA[0-9][0-9][0-9]' a critical 1)"
  assert_line "$out" "$(rec content 'x(ab)(ab)(ab)*' b critical 2)"
  assert_line "$out" "$(rec content 'y[^}][^}]?[^}]?z' c critical 3)"
  assert_line "$out" "$(rec content 'r' d critical 4)"
  assert_line "$out" "$(rec content 'a[{]x[}][{]' e critical 5)"
}

test_content_invalid_expressions() {
  rejects 'content \d+ x' "invalid regular expression: non-portable escape '\\d'"
  rejects 'content a\b x' "invalid regular expression: non-portable escape '\\b'"
  rejects 'content \<a x' "invalid regular expression: non-portable escape '\\<'"
  rejects 'content (ab x' "invalid regular expression: unbalanced parenthesis"
  rejects 'content ab) x' "invalid regular expression: unbalanced parenthesis"
  rejects 'content [ab x' "invalid regular expression: unterminated bracket expression"
  rejects 'content {2}a x' "invalid regular expression: repetition without an operand"
  rejects 'content a{3,1} x' "invalid regular expression: invalid repetition bounds"
  rejects 'content a{256} x' "invalid regular expression: invalid repetition bounds"
  rejects 'content ab\ x' "invalid regular expression: trailing backslash"
  rejects 'content [\] x' "invalid regular expression: backslash inside a bracket expression"
  rejects 'content [\]]{2} x' "invalid regular expression: backslash inside a bracket expression"
  rejects 'content [\d] x' "invalid regular expression: backslash inside a bracket expression"
  rejects 'content [[:alpha\:]] x' "invalid regular expression: backslash inside a bracket expression"
  rejects 'content [[:foo:]] x' "invalid regular expression: unknown character class 'foo'"
  rejects 'content [b-a] x' "invalid regular expression: invalid range 'b-a'"
  rejects 'content a|*b x' "invalid regular expression: repetition without an operand"
  rejects 'content *a x' "invalid regular expression: repetition without an operand"
  rejects 'content (+a) x' "invalid regular expression: repetition without an operand"
  rejects 'content a**b x' "invalid regular expression: repetition without an operand"
  rejects 'content ^*a x' "invalid regular expression: repetition without an operand"
  rejects 'content (|a) x' "invalid regular expression: empty alternative"
  rejects 'content (a|) x' "invalid regular expression: empty alternative"
  rejects 'content |a x' "invalid regular expression: empty alternative"
  rejects 'content a| x' "invalid regular expression: empty alternative"
  rejects 'content a||b x' "invalid regular expression: empty alternative"
  rejects 'content () x' "invalid regular expression: empty group"
  rejects 'content a(|)b x' "invalid regular expression: empty alternative"
  rejects 'content a{,3} x' "invalid regular expression: invalid repetition bounds"
  rejects 'content a{1,2,3} x' "invalid regular expression: invalid repetition bounds"
  rejects 'content ((ab){255}){20} x' "invalid regular expression: invalid repetition bounds"
}

# A pattern this OS's awk refuses fails the load like any other invalid rule.
test_pattern_rejected_by_awk_fails_load() {
  # shellcheck disable=SC2329 # invoked by riskmap_load through the name awk
  awk() {
    case $1 in
      -F)
        input=$(cat)
        case $input in *rejectme*) return 2 ;; esac
        printf '%s\n' "$input" | command awk "$@"
        ;;
      *)
        case ${P-} in *rejectme*) return 2 ;; esac
        command awk "$@"
        ;;
    esac
  }
  printf 'content ok x\ncontent rejectme y\ncontent fine z\n' > map.conf
  rc=0
  load map.conf > out 2> err || rc=$?
  assert_eq 65 "$rc"
  assert_eq "invalid rule at map.conf:2: invalid regular expression: rejected by awk" "$(cat err)"
  assert_eq "" "$(cat out)"
}

test_expansion_stays_under_the_cap() {
  printf 'content (ab){255}c x\n' > map.conf
  out=$(load map.conf)
  assert_eq 1021 "$(printf '%s\n' "$out" | cut -f 2 | awk '{ print length($0) }')"
}

test_bracket_expression_edge_cases() {
  printf '%s\n' 'content []a[:digit:]]{2} x' 'content [^]x]{1} y' 'content [a-]z w' > map.conf
  out=$(load map.conf)
  assert_line "$out" "$(rec content '[]a[:digit:]][]a[:digit:]]' x critical 1)"
  assert_line "$out" "$(rec content '[^]x]' y critical 2)"
  assert_line "$out" "$(rec content '[a-]z' w critical 3)"
}

test_every_invalid_line_is_reported() {
  printf 'path ok/** fine\nbogus x y\npath src/** core\npath src/** core nope\n' > map.conf
  rc=0
  load map.conf > out 2> err || rc=$?
  assert_eq 65 "$rc"
  assert_eq "invalid rule at map.conf:2: unknown kind 'bogus' (path, pathtoken, keyword, symbol or content)
invalid rule at map.conf:4: unknown lane 'nope' (critical or standard)" "$(cat err)"
  assert_eq "" "$(cat out)"
}

test_missing_file() {
  rc=0
  load nope.conf > out 2> err || rc=$?
  assert_eq 66 "$rc"
  assert_eq "cannot read risk map: nope.conf" "$(cat err)"
}

test_source_is_the_path_as_given() {
  mkdir -p 'dir with space=x'
  printf 'path a/** one\n' > 'dir with space=x/r.conf'
  out=$(load 'dir with space=x/r.conf')
  assert_eq "path${tab}a/**${tab}one${tab}critical${tab}dir with space=x/r.conf:1" "$out"
}

test_double_source_is_harmless() {
  . "$(lib_dir)/riskmap.sh"
  . "$(lib_dir)/riskmap.sh"
  printf 'path a/** one\n' > map.conf
  assert_eq "$(rec path 'a/**' one critical 1)" "$(riskmap_load map.conf)"
}

test_errors_return_instead_of_exiting() {
  . "$(lib_dir)/riskmap.sh"
  printf 'bad\n' > map.conf
  rc=0
  riskmap_load map.conf 2>/dev/null || rc=$?
  assert_eq 65 "$rc"
}

test_floors_conf_parses() {
  out=$(load "$(lib_dir)/floors.conf")
  items=$(printf '%s\n' "$out" | awk -F '\t' '{ print $3 "=" $4 }' | LC_ALL=C sort -u | tr '\n' ' ')
  assert_eq "auth=critical concurrency=critical data-migration=critical delivery=critical dependencies=standard money=critical public-contract=critical risk-map=critical secrets=critical tenant-isolation=critical test-harness=standard " "$items"
}

test_floors_conf_encodes_table_signals() {
  out=$(load "$(lib_dir)/floors.conf" | cut -f 1-4)
  for t in auth authn authz authentication authorization session sessions permission permissions rbac acl oauth jwt login logout password passwords credential credentials; do
    assert_line "$out" "pathtoken${tab}$t${tab}auth${tab}critical"
  done
  for t in tenant tenants tenancy rls; do
    assert_line "$out" "pathtoken${tab}$t${tab}tenant-isolation${tab}critical"
  done
  for t in billing payment payments checkout invoice invoices invoicing subscription subscriptions refund refunds payout payouts charge charges; do
    assert_line "$out" "pathtoken${tab}$t${tab}money${tab}critical"
  done
  assert_line "$out" "path${tab}**/migrations/**${tab}data-migration${tab}critical"
  assert_line "$out" "path${tab}**/.env.*${tab}secrets${tab}critical"
  assert_line "$out" "path${tab}.github/workflows/**${tab}delivery${tab}critical"
  assert_line "$out" "path${tab}**/api/**${tab}public-contract${tab}critical"
  assert_line "$out" "path${tab}**/pnpm-lock.yaml${tab}dependencies${tab}standard"
  assert_line "$out" "path${tab}**/conftest.py${tab}test-harness${tab}standard"
  assert_line "$out" "path${tab}.overdrive/risk-map.conf${tab}risk-map${tab}critical"
  assert_no_line "$out" "test-removed|untested-change|deletion|exec-bit|classification-failed"
}

# floor_hits ITEM LINE: 1 when a floor content rule of ITEM matches LINE in this OS's awk,
# used the way the classifier uses them: patterns read as data, never through -v.
floor_hits() {
  load "$(lib_dir)/floors.conf" | LINE=$2 awk -F '\t' -v item="$1" '
    $1 == "content" && $3 == item && ENVIRON["LINE"] ~ $2 { n++ }
    END { print (n > 0) }'
}

test_floor_content_patterns_match_in_awk() {
  assert_eq 1 "$(floor_hits secrets 'aws = "AKIAIOSFODNN7EXAMPLE"')"
  assert_eq 0 "$(floor_hits secrets 'AKIAIOSFODNN7EXAMPL')"
  assert_eq 1 "$(floor_hits secrets 'k = sk_live_4eC39HqLyj')"
  assert_eq 0 "$(floor_hits secrets 'k = sk_live_4eC39HqLy')"
  assert_eq 1 "$(floor_hits secrets '-----BEGIN RSA PRIVATE KEY-----')"
  assert_eq 1 "$(floor_hits secrets '-----BEGIN PRIVATE KEY-----')"
  assert_eq 1 "$(floor_hits secrets 'ghp_abcdefghijklmnopqrstuvwxyz0123456789')"
  assert_eq 0 "$(floor_hits secrets 'ghp_abcdefghijklmnopqrstuvwxyz012345678')"
  assert_eq 1 "$(floor_hits secrets 'SLACK=xoxb-1234')"
  assert_eq 1 "$(floor_hits secrets "api_key: 'abcdefghijkl'")"
  assert_eq 0 "$(floor_hits secrets 'api_key: "abcdefghijk"')"
  assert_eq 1 "$(floor_hits data-migration 'DROP TABLE users;')"
  assert_eq 1 "$(floor_hits data-migration 'alter   table users add column x int;')"
  assert_eq 1 "$(floor_hits data-migration 'TRUNCATE users;')"
  assert_eq 0 "$(floor_hits data-migration 'const s = truncate(title, MAX_TRUNCATE_LEN)')"
  assert_eq 1 "$(floor_hits data-migration 'truncate users;')"
  assert_eq 1 "$(floor_hits data-migration 'Truncate Table "users" cascade;')"
  assert_eq 1 "$(floor_hits data-migration 'Drop Table users;')"
  assert_eq 1 "$(floor_hits data-migration 'alter table x Drop Column y;')"
  assert_eq 1 "$(floor_hits data-migration 'await db.query("Delete From sessions")')"
  assert_eq 0 "$(floor_hits data-migration 'dropTables(); deleteFromCache(); alterTableName()')"
  assert_eq 1 "$(floor_hits tenant-isolation 'alter table t enable row level security;')"
  assert_eq 1 "$(floor_hits tenant-isolation 'Create Policy tenant_read ON t')"
  assert_eq 1 "$(floor_hits concurrency 'select id from jobs for update skip locked')"
  assert_eq 1 "$(floor_hits concurrency 'Select id From jobs For Update')"
  assert_eq 0 "$(floor_hits concurrency '// waiting for updates')"
  assert_eq 1 "$(floor_hits concurrency 'set transaction isolation level serializable;')"
  assert_eq 1 "$(floor_hits concurrency 'conn.set_session(isolation_level="SERIALIZABLE")')"
  assert_eq 1 "$(floor_hits concurrency 'BEGIN TRANSACTION SERIALIZABLE')"
  assert_eq 1 "$(floor_hits concurrency 'db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})')"
  assert_eq 1 "$(floor_hits tenant-isolation 'ALTER TABLE t ENABLE ROW LEVEL SECURITY;')"
  assert_eq 1 "$(floor_hits concurrency 'SELECT * FROM jobs FOR UPDATE SKIP LOCKED')"
  assert_eq 1 "$(floor_hits concurrency 'Atomics.wait(view, 0, 0)')"
  assert_eq 0 "$(floor_hits concurrency 'AtomicsX')"
  assert_eq 1 "$(floor_hits concurrency 'isolationLevel: Prisma.TransactionIsolationLevel.Serializable')"
  assert_eq 0 "$(floor_hits concurrency 'class User implements Serializable {')"
  assert_eq 1 "$(floor_hits auth 'const ok = await bcrypt.compare(a, b)')"
}

test_every_floor_pattern_compiles_in_awk() {
  load "$(lib_dir)/floors.conf" > records
  awk -F "\t" '$1 == "content" { print $2 }' records > patterns
  [ -s patterns ]
  while IFS= read -r p; do
    P=$p awk 'BEGIN { p = ENVIRON["P"]; if ("probe" ~ p) {} }' || { echo "awk rejected: $p" >&2; return 1; }
  done < patterns
}
