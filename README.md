# mk

Independent `mk` development-lifecycle orchestrator for the technical `m` layer.

`m` and its `pkg` package manager do not depend on `mk`. A package
installed with `pkg` provides `mk` and its managed Node.js execution
dependency. `mk` owns development-lifecycle orchestration, not installation.

## Source and release

```text
bin/mk                native Node.js command
lib/mk.lib.js         lifecycle engine
res/manual/           package-owned operational manuals
build.sh              standalone POSIX source-archive packager
tests/                isolated real-runtime integration test
```

The package-owned implementation and documentation are materialized beneath
the package's own `root/`; no `mk` implementation is projected into
`m/lib/sys`. To prepare the first source-only artifact without Node.js or
`mk` installed:

```sh
sh build.sh /path/to/new-output-directory
```

This produces `mk-v0.1.0-all.tar.gz` containing `bin/`, `lib/` and
`res/`, plus the matching copied `root/` for inspection. The output directory
must not exist. Source compilation is not required.

The versioned release package metadata is owned by `pkg-catalog`, not this
source repository. The catalog declares Node.js as an execution dependency,
and `pkg` owns command links, dependency installation, state and runtime
integration.

## Validation

```sh
sh tests/run.sh /path/to/m-checkout
```

The test uses a disposable copy of the actual `m` runtime, materializes the
package through the real `pkg` integration, installs managed Node.js, exercises
planning and execution, then checks `--watch` re-entry. The catalog tree in
`tests/fixtures` is *test data*, not the published catalog authority.

The current semantic contract is in
`rumiai-dev/specifications/rumiai-os/MK.md`; it remains authoritative during
the move from the previous `rumiai-os` monolith. Existing source and the
packaging proof are from PoC 073 at
`rumiai-dev-PoCs/mk-package-local-runtime@fdf655405eb3a22c34b549c013387d0fa01c34ea`.
