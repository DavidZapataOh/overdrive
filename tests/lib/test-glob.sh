#!/usr/bin/env bash
# Tests for plugins/overdrive/lib/glob.sh.

load_glob() { . "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/lib/glob.sh"; }

test_glob_double_star_zero_dirs() {
  load_glob
  glob_match src/auth/x.ts 'src/**/auth/*.ts'
  glob_match src/a/b/auth/x.ts 'src/**/auth/*.ts'
  glob_match x.sql '**/*.sql'
  glob_match db/migrations/x.sql '**/*.sql'
  glob_match infra/a/b.tf 'infra/**'
  if glob_match src/authx/x.ts 'src/**/auth/*.ts'; then return 1; fi
}

test_glob_star_stops_at_slash() {
  load_glob
  glob_match src/x.ts 'src/*.ts'
  if glob_match src/a/x.ts 'src/*.ts'; then return 1; fi
  glob_match a/b 'a/?'
  if glob_match a/ab 'a/?'; then return 1; fi
  if glob_match a// 'a/?'; then return 1; fi
}

test_glob_escapes_dots() {
  load_glob
  glob_match a.ts 'a.ts'
  if glob_match aXts 'a.ts'; then return 1; fi
}

test_glob_escapes_regex_metacharacters() {
  load_glob
  glob_match 'a+b(1)[x]{2}^$|\.ts' 'a+b(1)[x]{2}^$|\.ts'
  if glob_match aab 'a+b'; then return 1; fi
  if glob_match 'a' 'a|b'; then return 1; fi
}

test_glob_anchored_and_spaces() {
  load_glob
  if glob_match 'xsrc/a.ts' 'src/a.ts'; then return 1; fi
  if glob_match 'src/a.tsx' 'src/a.ts'; then return 1; fi
  glob_match 'apps/web/src/app/páginas legales/page.tsx' 'apps/web/src/app/*/page.tsx'
}

test_glob_to_regex_output() {
  load_glob
  assert_eq '^src/(.*/)?a\.ts$' "$(glob_to_regex 'src/**/a.ts')"
  assert_eq '^a/.*$' "$(glob_to_regex 'a/**')"
  assert_eq '^[^/]*\.[^/]$' "$(glob_to_regex '*.?')"
}

test_glob_cache_follows_pattern_change() {
  load_glob
  glob_match a.ts '*.ts'
  if glob_match a.ts '*.js'; then return 1; fi
  glob_match a.js '*.js'
}
