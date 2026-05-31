# Kiwiberry Remaining Plan

The pure Nim port, Kiwi-style compatibility coverage, ergonomic solver API,
finite-value validation, threaded identity counters, README examples, and API
docs are implemented. This file now tracks only work that is still open.

## Documentation

- Add a small `examples/` directory with copy-pasteable layout examples once the
  public API names settle.

## CI And Packaging

- Confirm CI runs `atlas install` and `nim test` on Linux, macOS, and Windows.
- Add a clean-checkout build that verifies the package works without
  `deps/kiwi`.
- Decide whether `deps/cssgrid` should remain only as a reference dependency or
  be removed from Atlas metadata entirely.

## Performance

- Add benchmarks based on representative UI layout workloads and Kiwi's
  Enaml-like benchmark shape.
- Profile row cell operations and pivot selection before changing data
  structures.
- Keep `OrderedTable` until benchmarks show it is the bottleneck.
- If needed, replace row cells with a sorted-vector map while preserving sorted
  iteration order, because that order affects deterministic Kiwi-compatible
  pivot choices.

## Robustness

- Add sanitizer runs if unsafe code or custom ownership hooks are introduced.
- Audit exception surfaces so solver operations raise only documented catchable
  errors for expected failure modes.
