# Tests and acceptance

Tests added/updated:
- `m-os/tests/context-run-smoke.sh`: POSIX isolated activation, argument
  preservation, selected pin and default fallback, invalid selector handling.
  **Observed:** isolated mock tests passed; not a full m-os installation.
- `m-mk/tests/run.sh`: real package integration, with optional context cases
  when the supplied m-os checkout contains context-run; app/child project
  dependency, --plan, watch trigger, fail-closed invalid selection.
  **Observed:** tests added, not run against a fully installed m-os runtime.
- `mk test`: root mk.json delegates the existing package bootstrap test;
  `mk test-jsc` delegates the optional JSC smoke test.

Outstanding acceptance: actually execute complete test matrix against a
current m-os installation with managed Node and pkg catalog, compare version 1
and 2 behavior, verify second runtime version cache invalidation, watch
re-entry/cancellation and context pin constraints. Passing static syntax or
mock tests is not equivalent to production acceptance.
