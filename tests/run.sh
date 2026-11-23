#!/bin/sh
set -eu

[ "$#" -eq 1 ] || { printf '%s\n' 'usage: sh tests/run.sh <m-or-rumiai-os-checkout>' >&2; exit 2; }
product=$1
self_dir=${0%/*}
[ "$self_dir" != "$0" ] || self_dir=.
poc_dir=$self_dir/..

work=${TMPDIR:-/tmp}/rumiai-mk-package-$$
cleanup()
{
  command -p -- rm -rf -- "$work"
}
trap cleanup 0
trap 'exit 130' HUP INT TERM

[ ! -e "$work" ] && [ ! -L "$work" ] || exit 3
command -p -- mkdir -p -- "$work/runtime"
root=$work/runtime
# A disposable copy, never the caller-owned checkout.
command -p -- cp -R -- "$product/." "$root/"
command -p -- rm -rf -- "$root/.git"

[ -x "$root/m" ] || { printf '%s\n' 'runtime bootstrap not executable' >&2; exit 4; }
[ -x "$root/bin/sys/pkg" ] || exit 5
# The legacy monolith must be stripped of its system mk. The independent
# m checkout already has no system mk and must stay untouched.
if [ -e "$root/bin/sys/mk" ] || [ -e "$root/lib/sys/js/mk.lib.js" ]
then
  [ -f "$root/lib/sys/js/mk.lib.js" ] || exit 6
  [ -f "$root/bin/sys/mk" ] || exit 6
  command -p -- rm -- "$root/bin/sys/mk" "$root/lib/sys/js/mk.lib.js"
fi
[ ! -e "$root/bin/sys/mk" ] || exit 7
[ ! -e "$root/lib/sys/js/mk.lib.js" ] || exit 8
# The source tree may carry selectors for a different host. Select the actual
# platform in the disposable clone, never in the caller-owned checkout.
"$root/m" osarch update
command -p -- mkdir -p -- "$root/pkg"

# m and pkg are usable without any Node.js installation in the copied root.
"$root/m" "$root/bin/sys/state-path" user sys mk cache > "$work/bootstrap.out"
[ -s "$work/bootstrap.out" ] || exit 9
printf '%s\n' 'bootstrap without mk PASS'

sh "$poc_dir/build.sh" "$work/distribution"
[ -s "$work/distribution/mk-v0.1.0-all.tar.gz" ] || exit 10
[ -f "$work/distribution/root/lib/mk.lib.js" ] || exit 11
[ ! -e "$work/distribution/root/lib/sys" ] || exit 12

command -p -- mkdir -- "$work/staging"
(
  CDPATH= cd -- "$work/staging"
  command -p -- tar -xzf "$work/distribution/mk-v0.1.0-all.tar.gz"
)
[ -x "$work/staging/bin/mk" ] || exit 13
[ -f "$work/staging/lib/mk.lib.js" ] || exit 14

# Invoke the genuine pkg materialization from within an initialized m context.
driver=$work/integrate
cat > "$driver" <<'EOF_DRIVER'
#!/bin/sh
[ -n "${m_ROOT:-}" ] || exit 1
. "$m_LIB_DIR/sys/sh/core.lib.sh" || exit 2
loadsyslib "osarch" || exit 3
loadsyslib "pkg/pkg-integration" || exit 4
pkg_integrate mk v0.1.0 "$1" "$2" || exit 5
pkg_default_apply mk v0.1.0 || exit 6
EOF_DRIVER
command -p chmod 700 "$driver"
"$root/m" "$driver" "$poc_dir/tests/fixtures/pkg/mk/all/n0001=v0.1.0" "$work/staging" || exit 15

[ -f "$root/pkg/mk@v0.1.0/root/lib/mk.lib.js" ] || exit 16
[ -x "$root/pkg/mk@v0.1.0/root/bin/mk" ] || exit 17
[ -L "$root/pkg/mk@v0.1.0/link/mk" ] || exit 18
[ -L "$root/bin/ext/mk" ] || exit 19
[ ! -e "$root/lib/sys/js/mk.lib.js" ] || exit 20
printf '%s\n' 'real pkg integration and package-local library PASS'

# Managed Node is acquired with pkg rather than from the host prerequisites.
"$root/m" "$root/bin/sys/pkg" install nodejs@v26.8.2
node_concrete=$("$root/m" "$root/bin/sys/pkg" default nodejs)
case "$node_concrete" in nodejs@*) :;; *) exit 21;; esac
[ -d "$root/pkg/$node_concrete/root" ] || exit 22

command -p -- mkdir -- "$work/project"
cat > "$work/project/mk.json" <<'EOF_PROJECT'
{
  "version": 1,
  "goals": {
    "check": ["identity"]
  },
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
"$root/m" mk --project "$work/project" --goals > "$work/goals"
[ "$(command -p -- cat -- "$work/goals")" = check ] || exit 23
"$root/m" mk --project "$work/project" --plan check > "$work/plan"
[ -s "$work/plan" ] || exit 24
"$root/m" mk --project "$work/project" check || exit 25
printf '%s\n' 'mk package launcher, plan, action and managed Node PASS'

# Watch must re-enter through the package cmd/mk launcher, not bin/sys/mk.
command -p -- mkdir -- "$work/watch"
printf '%s\n' initial > "$work/watch/source.txt"
cat > "$work/watch/mk.json" <<'EOF_WATCH'
{
  "version": 2,
  "goals": {"build": ["run"]},
  "operations": {
    "run": {
      "inputs": {"source": {"path": "source.txt"}},
      "action": {
        "type": "process",
        "command": "sh",
        "args": ["-c", "printf 'tick\\n' >> trace.log"]
      }
    }
  }
}
EOF_WATCH
"$root/m" mk --watch --project "$work/watch" build > "$work/watch.out" 2> "$work/watch.err" &
watch_pid=$!
watch_count=0
while [ "$watch_count" -lt 30 ]
do
  [ -f "$work/watch/trace.log" ] && break
  if ! kill -0 "$watch_pid" 2>/dev/null; then break; fi
  command -p -- sleep 1
  watch_count=$((watch_count+1))
done
if [ ! -f "$work/watch/trace.log" ]
then
  command -p -- cat -- "$work/watch.err" >&2
  kill -TERM "$watch_pid" 2>/dev/null || :
  wait "$watch_pid" 2>/dev/null || :
  printf '%s\n' 'watch did not run initial package-local lifecycle' >&2
  exit 26
fi
# The first action writes trace.log before the watch supervisor has finished
# re-snapshotting its baseline. Keep changing the real watched input until
# the next cycle occurs; a single immediate write is a startup race.
watch_count=0
while [ "$watch_count" -lt 30 ]
do
  if ! kill -0 "$watch_pid" 2>/dev/null; then break; fi
  watch_count=$((watch_count+1))
  printf 'changed-%s\n' "$watch_count" > "$work/watch/source.txt"
  command -p -- sleep 1
  n=$(command -p -- wc -l < "$work/watch/trace.log")
  [ "$n" -ge 2 ] && break
done
kill -TERM "$watch_pid" 2>/dev/null || :
wait "$watch_pid" 2>/dev/null || :
[ "$(command -p -- wc -l < "$work/watch/trace.log")" -ge 2 ] ||
{
  command -p -- cat -- "$work/watch.err" >&2
  printf '%s\n' 'watch did not rerun through package launcher' >&2
  exit 27
}
printf '%s\n' 'package-local watch re-entry PASS'


# Context-aware project goals are exercised through mk, not a separate app launcher.
# The bootstrap test remains independent so it can validate a fresh mk install.
if [ -x "$root/bin/sys/context-run" ]
then
  command -p -- mkdir -- "$work/context-child"
  cat > "$work/context-child/mk.json" <<'EOF_CHILD'
{
  "version": 2,
  "context": ["pkg=nodejs@v26.8.2"],
  "goals": {"build": ["generate"]},
  "operations": {
    "generate": {
      "action": {
        "type": "process",
        "command": "node",
        "args": ["-e", "require('node:fs').writeFileSync('marker.txt','context-child')"]
      }
    }
  }
}
EOF_CHILD
  command -p -- mkdir -- "$work/context-parent"
  cat > "$work/context-parent/mk.json" <<'EOF_PARENT'
{
  "version": 2,
  "goals": {"test": ["verify"]},
  "dependencies": {
    "child": {"project": "../context-child", "goals": {"test": ["build"]}}
  },
  "operations": {
    "verify": {
      "action": {
        "type": "process",
        "command": "node",
        "args": [
          "-e",
          "const fs=require('node:fs');if(fs.readFileSync('../context-child/marker.txt','utf8')!=='context-child')process.exit(63)"
        ]
      }
    }
  }
}
EOF_PARENT
  "$root/m" mk --project "$work/context-parent" --plan test > "$work/context-plan.json"
  [ -s "$work/context-plan.json" ] || exit 28
  "$root/m" mk --project "$work/context-parent" test || exit 29
  [ "$(command -p -- cat -- "$work/context-child/marker.txt")" = context-child ] || exit 30
  m_MK_WATCH_TRIGGER=1 "$root/m" mk --project "$work/context-child" build > "$work/context-digest"
  [ "$(command -p -- wc -c < "$work/context-digest")" -eq 65 ] || exit 31
  command -p -- mkdir -- "$work/context-invalid"
  cat > "$work/context-invalid/mk.json" <<'EOF_INVALID'
{
  "version": 2,
  "context": ["pkg=not-installed@v999"],
  "goals": {"test": ["must-not-run"]},
  "operations": {
    "must-not-run": {
      "action": {
        "type": "process",
        "command": "node",
        "args": ["-e", "require('node:fs').writeFileSync('ran.txt','wrong')"]
      }
    }
  }
}
EOF_INVALID
  if "$root/m" mk --project "$work/context-invalid" test > "$work/context-invalid.out" 2>&1
  then
    printf '%s\n' 'invalid project context incorrectly executed' >&2
    exit 32
  fi
  [ ! -e "$work/context-invalid/ran.txt" ] || exit 33
  "$root/m" mk --project "$work/context-invalid" --goals > "$work/context-goals"
  [ "$(command -p -- cat -- "$work/context-goals")" = test ] || exit 34
  printf '%s\n' 'context activation, dependency, --plan, watch digest, fail-closed PASS'
else
  printf '%s\n' 'context-run unavailable in supplied m checkout: optional context tests skipped'
fi
