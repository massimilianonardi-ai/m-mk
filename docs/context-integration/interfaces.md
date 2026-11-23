# Public interfaces

m-os: `m context-run <selector>... -- <command> [args...]`
creates a child-selected context then execs exactly the requested command.
`m context-run --resolve <facility> <constraint>...` checks the current
context's provider pin, falling back to pkg default if absent.

mk: `mk.json` version 2 gains optional root member:

```json
"context": ["full-context=development"]
```

It accepts the native context operand families: pkg=, provider.<facility>=,
system=, user=, locale=, osarch=, full-context=. Unknown members, empty arrays,
invalid strings and embedded newlines are errors. Version 1 rejects context.
Profiles do not gain a context override in this revision.

All existing mk CLI commands, goal mappings and operation forms are unchanged.
No shell is implicitly invoked for process actions. No automatic installation.
