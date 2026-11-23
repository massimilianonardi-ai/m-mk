# mk and m-os context integration

Status: implemented in m-mk source, with real m-os runtime acceptance pending.

- [Requirements and invariants](requirements.md)
- [Interfaces](interfaces.md)
- [Execution flow](flows.md)
- [Test coverage](tests.md)
- [Decisions and compatibility](decisions.md)

Sources: `lib/mk.lib.js` (mk), `bin/sys/context-run` (m-os). The bridge
is provided by m-os; mk does not replicate package/provider selection.
