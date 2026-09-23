# SourceFuse

A deterministic multi-source value arbitration library for MoonBit.

[![CI](https://github.com/wulisususu/SourceFuse/actions/workflows/ci.yml/badge.svg)](https://github.com/wulisususu/SourceFuse/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/wulisususu/SourceFuse)](https://github.com/wulisususu/SourceFuse/releases)

**Current release:** v0.1.1 · **Library targets:** wasm, wasm-gc, js, native · **License:** Apache-2.0

SourceFuse answers one narrow question:

> When multiple sources propose different values for the same field, which value should win, and why?

It turns that question into a reusable data model, a deterministic policy engine,
explicit conflict results, source provenance, and a machine-readable decision
trace.

## Why this is a library

SourceFuse keeps reconciliation semantics independent of application code:

- `core/` contains pure reconciliation logic with no file IO, HTTP, database,
  wall-clock, or AI-service dependency;
- identical candidates plus an identical policy produce the same result;
- locked values cannot be silently replaced;
- exact priority ties between different values remain explicit conflicts rather
  than falling back to array order;
- every result preserves the original evidence and an explanation trace;
- `wire/` provides a versioned JSON boundary without moving JSON concerns into
  the core.

A useful evaluation test is to ignore `cmd/` and `examples/`: `core/`,
`wire/`, tests, and the public API contract still form a complete reusable
library.

## 60-second demo

```bash
moon update
moon run cmd/sourcefuse examples/human-ocr-model/record.json
```

The output is a `sourcefuse.decision-report.v1` document containing the
canonical value, conflict state, applied rules, every considered candidate, and
the source records supporting the result.

For the bundled example:

```text
Human      "张珊"  confirmed
OCR        "张珊"  confidence=98
LLM        "张山"  confidence=91

          ↓ reconcile

winner: "张珊"
reason: confirmed evidence outranks ordinary proposals
supporters: Human + OCR
```

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for the guided walkthrough.

## Typed core API

A consumer can use the reconciliation package directly without JSON or the CLI.

```moonbit
let candidates = [
  @sourcefuse.candidate(
    "张珊",
    "operator",
    @sourcefuse.Human,
    100,
    100,
    2,
    @sourcefuse.Confirmed,
  ),
  @sourcefuse.candidate(
    "张山",
    "model",
    @sourcefuse.Model,
    20,
    91,
    3,
    @sourcefuse.Proposed,
  ),
]

let result = @sourcefuse.reconcile(candidates)
```

For custom behavior, callers can choose normalization, whether confirmed values
dominate ordinary proposals, ranking dimensions, and per-`SourceKind`
authority overrides.

Default deterministic precedence:

```text
locked
  ↓
confirmed
  ↓
authority
  ↓
confidence
  ↓
revision
  ↓
different values still tied → explicit conflict
```

Candidate count is not a voting dimension. `supporter_count` is explanatory
evidence after a decision, not majority voting.

## Architecture

```text
typed candidates
      │
      v
   core/        pure deterministic policy engine
      │
      v
DecisionReport
      │
      v
   wire/        versioned JSON adapter
      │
      └──────────────> cmd/sourcefuse
                        native reference adapter
```

The CLI exists only to make evaluation and scripting convenient. It contains no
independent reconciliation policy.

## JSON wire API

Input schema:

```text
sourcefuse.record.v1
```

Output schema:

```text
sourcefuse.decision-report.v1
```

End-to-end adapter:

```moonbit
match @wire.reconcile_record_json(text, pretty=true) {
  Ok(report_json) => println(report_json)
  Err(error) => println(error.message)
}
```

The output preserves `considered` and `supporters` candidate arrays so a
consumer can audit the decision against the original source evidence instead of
seeing only aggregate counts.

## Project boundary

SourceFuse intentionally does **not** implement HTTP/API testing, mock/replay,
workflow orchestration, CRDT replication, database synchronization, entity
resolution, probabilistic truth discovery, or LLM-agent orchestration.

v0.1 reconciles textual `String` field values. Domain-specific numbers, dates,
identifiers, enums, or structured values should be canonicalized by the caller
before reconciliation.

See [docs/DIFFERENTIATION.md](docs/DIFFERENTIATION.md) for the design boundary.

## Repository map

| Path | Purpose |
| --- | --- |
| `core/` | candidate model, policy, deterministic reconciliation, record reports |
| `wire/` | stable v1 JSON parsing and serialization |
| `examples/` | small runnable scenarios exercising distinct semantics |
| `cmd/sourcefuse/` | native reference adapter only |
| `docs/API.md` | intended public API contract |
| `docs/EVALUATION.md` | shortest reviewer verification path |
| `docs/POLICY.md` | policy and ranking semantics |
| `docs/WIRE_SCHEMA.md` | JSON schema contract |
| `CHANGELOG.md` | release history and compatibility notes |

## Validation

Every change is checked on Ubuntu and Windows native builds. The reusable
library is also checked, tested, and built on `wasm`, `wasm-gc`, `js`, and
`native`.

CI additionally verifies the publishable file set, release metadata, real CLI
examples, the core dependency boundary, and generated MoonBit public interfaces.

Release history is in [CHANGELOG.md](CHANGELOG.md). The release process is in
[docs/RELEASE.md](docs/RELEASE.md).

## License

Apache-2.0
