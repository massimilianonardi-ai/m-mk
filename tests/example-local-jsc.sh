#!/bin/sh
set -eu

[ "$#" -eq 1 ] || {
  printf '%s\n' 'usage: sh tests/example-local-jsc.sh /absolute/path/to/m' >&2
  exit 2
}
m_bin=$1
[ -x "$m_bin" ] || {
  printf '%s\n' "m bootstrap is not executable: $m_bin" >&2
  exit 3
}

test_dir=${0%/*}
[ "$test_dir" != "$0" ] || test_dir=.
repo_dir=$(CDPATH= cd -- "$test_dir/.." && pwd -P)
work=$(mktemp -d "${TMPDIR:-/tmp}/mk-local-jsc.XXXXXXXX")
trap 'command -p -- rm -rf -- "$work"' 0
trap 'exit 130' HUP INT TERM
command -p -- cp -R -- "$repo_dir/examples/local-jsc/." "$work/"

"$m_bin" mk --project "$work/app" --plan run > "$work/plan.json"
[ -s "$work/plan.json" ] || exit 4

result=$("$m_bin" mk --project "$work/app" run) || exit 5
[ "$result" = 'Hello, mk!' ] || {
  printf '%s\n' "unexpected command output: $result" >&2
  exit 6
}
[ -s "$work/library/build/greeting.js" ] || exit 7
"$m_bin" mk --project "$work/app" test > "$work/test.log" || exit 8
grep 'PASS: local JSC dependency' "$work/test.log" >/dev/null || exit 9

printf '%s\n' 'PASS: mk run/test with local JSC project dependency'
