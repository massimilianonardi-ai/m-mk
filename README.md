# mk

Independent source for `mk`, the development-lifecycle orchestrator of the technical `m` layer.

`mk` is optional: the `m` bootstrap and `pkg` work without it. The `mk`
runtime requires the managed `nodejs` package and is installed using `pkg`.

The package's implementation lives entirely below its materialized `root/`:
`bin/mk` is a native Node.js entrypoint and `lib/mk.lib.js` is its engine.
No `mk` implementation library is installed in `m/lib/sys`.

A source-only release archive is produced using the POSIX `build.sh` packaging
script; producing the archive does not require Node.js or `mk`.

Current development contracts belong to `rumiai-dev`, especially
`specifications/rumiai-os/MK.md`. Operational help accompanies the package.
