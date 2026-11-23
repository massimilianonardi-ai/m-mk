# Decisions and compatibility

ADR-1 [approved] Retain mk as development-lifecycle orchestrator: goals,
operations, project dependencies, plans, watch and incremental compilation.
Do not replace mk with context.

ADR-2 [approved] Context is owned by m-os. Add one small isolated POSIX
process/query boundary rather than duplicating PATH/CLASSPATH/provider logic
in mk. No implicit package installation or persistent configuration changes.

ADR-3 [approved] Version-2 mk.json optional context array; absent means
legacy environment; native selectors are passed through in order.

ADR-4 [approved] If a validated active context pins a provider, check that
provider against the declared facility requirements. With no pin use pkg
system-default resolution. Legacy m-os without context-run keeps the old
requirement path when no project context is specified.

ADR-5 [implementation] Apply context at project-boundary re-entry instead of
per-action spawning, so build fingerprints, planning and watch observe the
same environment. Avoid changing mk's existing action model.

Excluded: changing package installation, extending version-1 config, per-
operation context overrides, new project manifest formats, changing CLI
positional operands, and replacement of existing bootstrap test drivers.
