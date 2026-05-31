# Kiwiberry Remaining Plan

The pure Nim port, Kiwi-style compatibility coverage, ergonomic solver API,
finite-value validation, threaded identity counters, README examples, API docs,
the first UI-grid benchmark/profile pass, and an upstream Kiwi comparison
benchmark are implemented. This file now tracks only work that is still open.

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

- Add larger benchmark shapes if production layouts expose scaling problems
  beyond the current 2x6 grid workload.
- Profile scalar validation overhead before considering a trusted internal
  arithmetic path.
- If row-cell tables stop scaling, evaluate a sorted-vector map while preserving
  deterministic Kiwi-compatible pivot choices.

## Robustness

- Add sanitizer runs if unsafe code or custom ownership hooks are introduced.
- Audit exception surfaces so solver operations raise only documented catchable
  errors for expected failure modes.
