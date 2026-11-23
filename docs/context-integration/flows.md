# Context execution flows

```text
mk --project app run
   │ read/validate mk.json
   ├─ context absent → legacy execution
   └─ context present → m-os context-run selectors -- node <mk> ...
        │ native context() activation inside child
        └─ mk re-entry with activated context
             ├─ dependency planning/execution (children may select own context)
             ├─ requirement checks via context-run --resolve
             ├─ process actions / incremental fingerprint using effective PATH
             └─ watch trigger fingerprints using same selected environment
```

The re-entry marker identifies only the current project/context combination.
It is scrubbed from ordinary operation/dependency child environments and is
re-added only for its own selected re-entry. Dependency chain ancestry is
preserved explicitly. Context invalidation fails before project actions.

Watch supervisor remains in its original environment. Each trigger check and
lifecycle run re-enters through mk and selects context when required. Watch
digests for dependency projects use their own context.
