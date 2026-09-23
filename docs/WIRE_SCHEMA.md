# SourceFuse Wire Schemas

SourceFuse keeps JSON at the adapter boundary.

```text
JSON
 ↓
wire/
 ↓
core/
 ↓
DecisionReport
 ↓
wire/
 ↓
JSON
```

The `core/` package does not import the JSON package.

## Input schema

Schema identifier:

```text
sourcefuse.record.v1
```

Minimal document:

```json
{
  "schema_version": "sourcefuse.record.v1",
  "fields": []
}
```

### Record

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `schema_version` | string | yes | must equal `sourcefuse.record.v1` |
| `default_policy` | object | no | omitted = Core default policy |
| `fields` | array | yes | declaration order is preserved |

### Field

```json
{
  "name": "name",
  "policy": {},
  "candidates": []
}
```

`policy` is optional. When omitted, the record default is used.

### Candidate

Every provenance/ranking field is explicit in v1:

```json
{
  "value": "张珊",
  "source_id": "operator",
  "source_kind": "human",
  "authority": 100,
  "confidence": 100,
  "revision": 2,
  "state": "confirmed"
}
```

Allowed `source_kind` values:

- `human`
- `device`
- `rule`
- `model`
- `external`

Allowed `state` values:

- `proposed`
- `confirmed`
- `locked`

`authority`, `confidence`, and `revision` must be JSON integer numbers.
The v1 wire layer rejects decimal values instead of truncating them.

### Policy

All policy fields are optional inside a policy object:

```json
{
  "normalization": "ascii_trim_case_fold",
  "confirmed_dominates": true,
  "rank_order": ["authority", "confidence", "revision"],
  "source_authorities": [
    { "source_kind": "human", "authority": 100 },
    { "source_kind": "model", "authority": 20 }
  ]
}
```

Defaults within an explicitly supplied policy object:

- `normalization`: `exact`
- `confirmed_dominates`: `true`
- `rank_order`: authority → confidence → revision
- `source_authorities`: empty

Normalization values:

- `exact`
- `ascii_trim`
- `ascii_trim_case_fold`

Rank values:

- `authority`
- `confidence`
- `revision`

## Structured errors

Parsing returns `WireError`:

```text
kind
path
message
```

Example:

```text
kind: InvalidValue
path: $.fields[0].candidates[1].state
message: expected proposed, confirmed, or locked
```

Stable error categories:

- `InvalidJson`
- `UnsupportedSchema`
- `MissingField`
- `InvalidType`
- `InvalidValue`

The path uses a JSONPath-like notation for diagnostics only. It is not a
general JSONPath implementation.

Unknown `schema_version` values are rejected. v1 never silently interprets a
future schema as v1.

## Output schema

Schema identifier:

```text
sourcefuse.decision-report.v1
```

Shape:

```json
{
  "schema_version": "sourcefuse.decision-report.v1",
  "status": "reconciled",
  "summary": {
    "declared_fields": 2,
    "resolved_fields": 1,
    "conflicted_fields": 1
  },
  "issues": [],
  "fields": [
    {
      "name": "name",
      "status": "resolved",
      "value": "张珊",
      "conflict": null,
      "candidate_count": 3,
      "supporter_count": 2,
      "considered": [
        {
          "value": "张珊",
          "source_id": "operator",
          "source_kind": "human",
          "authority": 100,
          "confidence": 100,
          "revision": 2,
          "state": "confirmed"
        }
      ],
      "supporters": [
        {
          "value": "张珊",
          "source_id": "operator",
          "source_kind": "human",
          "authority": 100,
          "confidence": 100,
          "revision": 2,
          "state": "confirmed"
        }
      ],
      "trace": [
        {
          "rule": "confirmed_dominates",
          "detail": "confirmed candidates outrank ordinary proposals under this policy"
        }
      ]
    }
  ]
}
```

Record status values:

- `reconciled`
- `invalid`

Field status values:

- `resolved`
- `conflict`

Each field also carries two provenance arrays:

- `considered`: every original candidate supplied for that field;
- `supporters`: every original candidate whose normalized value supports the
  resolved canonical value; empty for unresolved conflicts.

Candidate objects in these arrays use the same provenance/ranking shape as the
input candidate schema. `candidate_count` and `supporter_count` are
convenience summaries of those arrays. Supporter count is explanatory evidence,
not a majority-voting rule.

The decision `trace` records the deterministic rule path. Consumers that need
an auditable explanation should read the trace together with `considered` and
`supporters`, which identify exactly which source evidence participated in
and corroborated the decision.

Conflict identifiers:

- `empty_input`
- `locked_conflict`
- `equal_priority_conflict`

Record issues currently include:

```json
{
  "kind": "duplicate_field_name",
  "field_name": "name"
}
```

## Determinism

For identical `DecisionReport` data, `decision_report_json(...)` emits the
same JSON representation.

Arrays preserve their semantic order:

- fields preserve declaration order;
- issues preserve deterministic detection order;
- considered candidates preserve caller order;
- supporters preserve caller order among corroborating candidates;
- decision traces preserve rule application order.

Consumers should rely on JSON field names rather than object-member textual
ordering.

## Convenience adapter

```moonbit
reconcile_record_json(text, pretty=true)
```

performs:

```text
parse_record_document
→ reconcile_record
→ decision_report
→ decision_report_json
```

and returns `Result[String, WireError]`.

It performs no HTTP, file IO, system-clock reads, database access, or AI calls.
