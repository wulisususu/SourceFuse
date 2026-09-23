# Evaluation path

A reviewer can verify SourceFuse without reading the whole repository.

## 1. Apply the library-only test

Ignore `cmd/` and `examples/` first.

The remaining `core/`, `wire/`, tests, API contract, and schema
documentation still provide a complete reusable library:

```text
Candidate + Policy
       |
       v
 deterministic reconcile
       |
       +--> resolved value or explicit conflict
       +--> complete provenance
       +--> machine-readable decision trace
```

This is the primary architectural boundary of the project. The CLI is only a
reference adapter.

## 2. Read the reusable implementation

Start with:

```text
core/model.mbt
core/policy.mbt
core/reconcile.mbt
core/record_reconcile.mbt
core/report.mbt
```

The critical behavior to verify is:

- locked values are a non-configurable invariant;
- confirmed values may dominate proposals under policy;
- configured rank dimensions are applied deterministically;
- different values with equal final priority remain conflicts;
- input order is never an implicit tie-breaker;
- original candidates survive into decision provenance.

## 3. Inspect the tests

The tests cover:

- empty candidate sets;
- locked-value resolution and locked conflicts;
- confirmed precedence;
- authority / confidence / revision ordering;
- exact-tie conflicts;
- normalization semantics, including the ASCII-only case-fold contract;
- `SourceKind` authority overrides;
- record-level duplicate validation;
- field-level conflict isolation;
- provenance preservation;
- wire validation, paths, and deterministic serialization.

## 4. Run the end-to-end examples

```bash
moon update
moon run cmd/sourcefuse examples/human-ocr-model/record.json
moon run cmd/sourcefuse examples/device-human-model/record.json
moon run cmd/sourcefuse examples/conflicted-record/record.json
```

They demonstrate three distinct properties:

```text
human-ocr-model       confirmed precedence + normalization + provenance
device-human-model    SourceKind authority override
conflicted-record     explicit field conflict without discarding other fields
```

## 5. Verify portability

CI checks, tests, and builds the reusable library on:

```text
wasm
wasm-gc
js
native
```

Native CI runs on both Ubuntu and Windows. `cmd/sourcefuse` is explicitly
native-only and does not alter the portability contract of `core/` or
`wire/`.

## 6. Verify the public contract

Read:

```text
docs/API.md
docs/POLICY.md
docs/WIRE_SCHEMA.md
docs/DIFFERENTIATION.md
```

CI executes `moon info --target native` and checks the generated public
interfaces for required v0.1 entrypoints. It also validates the publishable
module file set and release-version metadata.

## 7. Verify a release

The release checklist is in `docs/RELEASE.md`; version history and
compatibility notes are in `CHANGELOG.md`.
