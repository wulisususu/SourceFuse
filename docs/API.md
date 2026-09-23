# Public API contract — v0.1

This page defines the intended public surface of SourceFuse v0.1. It is a
review aid and a compatibility checklist, not a substitute for generated
MoonBit `.mbti` interfaces.

## `core/`

### Data model

Public data types:

- `SourceKind`
- `CandidateState`
- `Candidate`
- `ConflictKind`
- `ReconcileStatus`
- `DecisionRule`
- `DecisionStep`
- `ReconcileResult`
- `NormalizationMode`
- `RankDimension`
- `SourceAuthority`
- `ReconcilePolicy`
- `FieldInput`
- `RecordInput`
- `RecordIssue`
- `RecordStatus`
- `FieldResult`
- `RecordResult`
- `FieldDecision`
- `DecisionReport`

The v0.1 structs intentionally expose their fields because callers need direct
access to provenance, traces, status, and resolved values.

### Constructors and policy helpers

```text
candidate
default_policy
policy
source_authority
normalize_value
field
field_with_policy
record
record_with_policy
```

### Reconciliation entrypoints

```text
reconcile
reconcile_with_policy
reconcile_record
record_fully_resolved
decision_report
```

`reconcile_with_policy` and `reconcile_record` are the main typed library
entrypoints. No public core API performs IO, accesses the system clock, calls
HTTP services, or invokes an AI model.

## `wire/`

Stable schema identifiers:

```text
RECORD_SCHEMA = sourcefuse.record.v1
DECISION_REPORT_SCHEMA = sourcefuse.decision-report.v1
```

Public entrypoints:

```text
parse_record_document
decision_report_json
reconcile_record_json
```

Public error model:

- `WireErrorKind`
- `WireError`

The wire package may depend on JSON support. The core package must not depend on
the wire package or JSON.

## CLI boundary

`cmd/sourcefuse` is not a reusable policy API. It is a native-only reference
adapter that reads one file and delegates all reconciliation semantics to
`wire/` and `core/`.

## Compatibility rules

For the `0.1.x` line:

- existing public function names and schema identifiers should not be removed
  without an explicit compatibility decision;
- changing precedence, normalization, conflict semantics, or provenance shape
  requires tests and a changelog entry;
- a new incompatible JSON shape requires a new schema identifier rather than
  silently changing `*.v1`;
- deterministic behavior for identical input + policy is invariant.
