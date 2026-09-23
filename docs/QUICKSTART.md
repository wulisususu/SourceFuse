# Quickstart

This is the shortest path from clone to an auditable SourceFuse decision.

## 1. Resolve dependencies and run tests

```bash
moon update
moon test --target native
```

The core and wire packages are also validated in CI on `wasm`, `wasm-gc`,
`js`, and `native`.

## 2. Run the reference CLI

```bash
moon run cmd/sourcefuse examples/human-ocr-model/record.json
```

The CLI reads a `sourcefuse.record.v1` JSON document and prints a
`sourcefuse.decision-report.v1` document.

For the bundled example, inspect:

- `fields[0].value` → `"张珊"`
- `fields[0].supporter_count` → `2`
- `fields[0].supporters` → operator + OCR provenance
- `fields[0].trace` → confirmation/normalization decision path

## 3. Try the authority example

```bash
moon run cmd/sourcefuse examples/device-human-model/record.json
```

This record deliberately gives the model a higher raw `authority` value than
the device. The policy's `source_authorities` override changes the effective
ranking to Device > Human > Model, so the card-reader value resolves.

## 4. Try a partial conflict

```bash
moon run cmd/sourcefuse examples/conflicted-record/record.json
```

The phone field has two different values with exactly equal priority, so it
returns `equal_priority_conflict`. The locked name and corroborated city still
resolve independently.

## Use SourceFuse as a library

For direct MoonBit integration, depend on `core/` for typed reconciliation
or `wire/` for the versioned JSON boundary. The CLI is only a reference
adapter and contains no decision logic.

```text
application candidates
        |
        v
      core/        deterministic policy engine
        |
        v
 DecisionReport
        |
        v
      wire/        versioned JSON adapter
        |
        +----> cmd/sourcefuse   native reference adapter
```
