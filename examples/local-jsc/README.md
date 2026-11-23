# Local JSC library consumed by a Node.js command

This example exercises the existing `mk` version-2 project dependency
mechanism. Nothing is published to `pkg-catalog`: the library is compiled
directly from the current local source tree when the application runs.

Prerequisites: a working `m` installation with managed Node.js and the
independent `mk` and `jsc` packages installed and selected as defaults.

From the `m-mk` repository root:

```sh
m mk --project examples/local-jsc/app --plan run
m mk --project examples/local-jsc/app run
m mk --project examples/local-jsc/app test
m mk --project examples/local-jsc/library build
```

Or, from `examples/local-jsc/app`, run `m mk run` and `m mk test`.
In an initialized `m` shell where `mk` is on PATH, use `mk run`.

The application project declares a dependency on the sibling `library`
project: `run` and `test` request the library's `build` goal before
running Node.js. The library invokes `jsc` in a normal process operation,
producing `library/build/greeting.js`. The application loads that CommonJS
artifact without any published package, custom module loader or context
manipulation.

`mk` itself neither installs missing packages nor changes the caller's
context. If `jsc` or `node` cannot be found in the selected `m`
environment, configure/install the needed packages explicitly.

An isolated smoke test (copies the example to a temporary directory):

```sh
sh tests/example-local-jsc.sh /absolute/path/to/m
```

The smoke test is separate from `tests/run.sh` because that package-local
`mk` test must not acquire a new JSC dependency.
