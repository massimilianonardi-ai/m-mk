#!/bin/sh
# Exercise a real published mk release through the public pkg command.
set -eu

[ "$#" -eq 1 ] || { printf '%s\n' 'usage: sh tests/install-live.sh <m-checkout>' >&2; exit 2; }
source_root=$1
work=$(mktemp -d "${TMPDIR:-/tmp}/mk-install-live.XXXXXXXX") || exit 3
trap 'command -p -- rm -rf -- "$work"' 0
trap 'exit 130' HUP INT TERM

command -p -- mkdir -- "$work/runtime"
command -p -- cp -R -- "$source_root/." "$work/runtime/"
root=$work/runtime
command -p -- rm -rf -- "$root/.git"
[ -x "$root/m" ] || exit 4
[ ! -e "$root/bin/sys/mk" ] || exit 5
[ ! -e "$root/lib/sys/js/mk.lib.js" ] || exit 6

"$root/m" osarch update

# The system bootstrap must remain functional with no mk or Node.js installed.
"$root/m" state-path user sys mk cache > "$work/state.txt"
[ -s "$work/state.txt" ] || exit 7
[ ! -e "$root/pkg/mk@v0.1.0" ] || exit 8

# This is the public release/catalog path, not the direct integration fixture.
"$root/m" pkg install mk@v0.1.0
[ -x "$root/pkg/mk@v0.1.0/root/bin/mk" ] || exit 9
[ -f "$root/pkg/mk@v0.1.0/root/lib/mk.lib.js" ] || exit 10
[ -f "$root/pkg/mk@v0.1.0/root/res/manual/mk" ] || exit 11
[ -f "$root/pkg/mk@v0.1.0/root/res/manual/mk.lib.js" ] || exit 12
[ ! -e "$root/lib/sys/js/mk.lib.js" ] || exit 13
[ -L "$root/bin/ext/mk" ] || exit 14
[ "$("$root/m" pkg default mk)" = "mk@v0.1.0" ] || exit 15

node_concrete=$("$root/m" pkg default nodejs)
case "$node_concrete" in nodejs@v26*) : ;; *) exit 16 ;; esac
[ -d "$root/pkg/$node_concrete/root" ] || exit 17

command -p -- mkdir -- "$work/project"
cat > "$work/project/mk.json" <<'EOF_PROJECT'
{
  "version": 1,
  "goals": {"check": ["identity"]},
  "operations": {
    "identity": {
      "action": {
        "type": "process",
        "command": "node",
        "args": [
          "-e",
          "const fs=require('node:fs'),path=require('node:path');const actual=fs.realpathSync(process.execPath),expected=fs.realpathSync(process.env.EXPECTED_NODE_ROOT);if(!actual.startsWith(expected+path.sep))process.exit(51);"
        ]
      }
    }
  }
}
EOF_PROJECT
EXPECTED_NODE_ROOT="$root/pkg/$node_concrete/root"
export EXPECTED_NODE_ROOT

[ "$("$root/m" mk --project "$work/project" --goals)" = check ] || exit 18
"$root/m" mk --project "$work/project" --plan check > "$work/plan"
[ -s "$work/plan" ] || exit 19
"$root/m" mk --project "$work/project" check

printf '%s\n' 'PASS: public pkg install mk@v0.1.0, managed Node, real launcher and action'
