# SourceFuse examples

These inputs are intentionally small enough to inspect by eye while exercising
three different library properties.

| Example | What it demonstrates | Expected result |
| --- | --- | --- |
| `human-ocr-model` | confirmation precedence + normalization + provenance | `name = 张珊`; operator and OCR both support the canonical value |
| `device-human-model` | application-defined `SourceKind` authority | device/card-reader value wins despite lower raw authority than other candidates |
| `conflicted-record` | field-level failure isolation | `name` and `city` resolve; `phone` remains an `equal_priority_conflict` |

Run any example through the native reference adapter:

```bash
moon run cmd/sourcefuse examples/human-ocr-model/record.json
moon run cmd/sourcefuse examples/device-human-model/record.json
moon run cmd/sourcefuse examples/conflicted-record/record.json
```

The CLI emits the stable `sourcefuse.decision-report.v1` JSON document,
including the decision trace and full `considered` / `supporters`
provenance arrays.

A valid record may still contain conflicted fields. In the third example the
record-level status is `reconciled`, while the summary reports two resolved
fields and one conflicted field. This is deliberate failure isolation, not a
partial parser failure.
