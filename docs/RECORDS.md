# Structured Record Reconciliation

Gate 3 extends SourceFuse from one logical field to a structured record.

## Data flow

```text
RecordInput
├─ name
│  ├─ Candidate(Human, "张珊")
│  ├─ Candidate(OCR, "张珊")
│  └─ Candidate(Model, "张山")
├─ id_number
│  ├─ Candidate(Device, "3201...")
│  └─ Candidate(OCR, "3201...")
└─ phone
   ├─ Candidate(Human, "138...")
   └─ Candidate(CRM, "139...")

          ↓ reconcile_record

RecordResult
├─ name       → Resolved
├─ id_number  → Resolved
└─ phone      → Conflict

          ↓ decision_report

DecisionReport
├─ resolved_fields = 2
├─ conflicted_fields = 1
└─ per-field trace summaries
```

## Field policies

A record owns one `default_policy`. Any field may override it.

This supports mixed semantics without forking the engine:

- identity fields can prefer Device authority;
- user-editable fields can prefer Human confirmations;
- labels can use ASCII trim/case-fold normalization;
- versioned external fields can rank Revision first.

## Failure isolation

One field conflict does not abort other fields.

For example, an ambiguous phone number does not prevent a locked identity field
from resolving.

This is deliberate: SourceFuse models independent field decisions rather than
a transaction that must succeed or fail as one unit.

## Duplicate field names

Duplicate logical names invalidate the record before any field is reconciled:

```text
name
phone
name
  ↓
RecordInvalid
DuplicateFieldName("name")
```

The engine does not merge duplicate declarations implicitly because doing so
would make field policy and provenance semantics ambiguous.

Duplicate issues are reported once per duplicated name in the order the
duplicate is first observed.

## DecisionReport

`decision_report(record_result)` creates a pure-data summary suitable for
later adapters.

Each `FieldDecision` includes:

- field name;
- resolved/conflict status;
- canonical resolved value, if any;
- conflict kind, if any;
- candidate count;
- supporter count;
- complete decision trace.

Gate 3 deliberately does not serialize this model to JSON or write files.
Serialization belongs to an adapter layer so the core remains deterministic and
runtime-independent.

## Ordering

Valid record field results preserve declaration order.

SourceFuse never sorts fields behind the caller's back. Candidate ranking still
uses policy dimensions rather than candidate array position.
