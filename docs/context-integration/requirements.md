# Requirements and invariants

REQ-1 Preserve existing CLI, version-1 and version-2 mk.json semantics
when no context is declared. No new mandatory project field.

REQ-2 A version-2 project may select an installed context via one ordered
array of native selectors, before its planning/operations run.

REQ-3 Context activation must not modify caller environment or persistent
m-os defaults. Missing/invalid selections fail before project work.

REQ-4 Provider facility checks use a validated context provider pin if one
exists. With no pin, keep pkg system-default semantics. Older m-os without
the bridge keeps the legacy query if no project context is requested.

REQ-5 Preserve dependency-cycle tracking and child project environments,
watch triggers and signal behavior, cache correctness and plan introspection.

REQ-6 The normal development test surface is `mk test`; bootstrap tests
remain callable independently before installing mk.
