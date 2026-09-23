# Evaluation path

A reviewer can verify the project without reading the whole repository.

## 1. Understand the problem

Read the first section of `README.md` and `docs/PROJECT_SCOPE.md`.

SourceFuse solves deterministic arbitration when multiple sources disagree on
one logical field. It is not an agent framework, HTTP tool, or workflow product.

## 2. Inspect the reusable implementation

Read:

```text
core/model.mbt
core/policy.mbt
core/reconcile.mbt
core/record_reconcile.mbt
core/report.mbt
```

These files contain the reusable reconciliation library.

## 3. Inspect the tests

The tests demonstrate:

- locked-value invariants;
- confirmed precedence;
- authority/confidence/revision ordering;
- exact-tie conflicts rather than array-order selection;
- normalization semantics;
- source-authority overrides;
- field-level failure isolation;
- provenance preservation;
- wire validation and deterministic serialization.

## 4. Run an end-to-end example

```bash
moon update
moon run cmd/sourcefuse examples/human-ocr-model/record.json
```

The result exposes the selected canonical value, rule trace, every considered
candidate, and the sources that support the result.

## 5. Verify portability

The reusable library is checked, tested, and built on:

```text
wasm
wasm-gc
js
native
```

Native CI also runs on Ubuntu and Windows. The CLI is explicitly native-only and
does not reduce the portability contract of `core/` or `wire/`.

## 6. Verify the API boundary

Read `docs/API.md` and `docs/WIRE_SCHEMA.md`. CI generates MoonBit public
interfaces and checks required entrypoints before a release can be considered
green.
