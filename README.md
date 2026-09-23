# SourceFuse

A deterministic multi-source value arbitration library for MoonBit.

**Current release:** v0.1.0 · **Library targets:** wasm, wasm-gc, js, native ·
**License:** Apache-2.0

SourceFuse answers one narrow question:

> When multiple sources propose different values for the same field, which value should win, and why?

Typical sources include humans, devices, rules, models, and external systems. The core library produces a deterministic decision plus an explainable decision trace.

## 60-second demo

```bash
moon update
moon run cmd/sourcefuse examples/human-ocr-model/record.json
```

The output is a versioned decision report containing the canonical value,
conflict state, applied rule trace, and complete source provenance.

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for the guided walkthrough and
[examples/README.md](examples/README.md) for all bundled scenarios.

## Example

```text
Human      "张珊"  confirmed
OCR        "张珊"  confidence=98
LLM        "张山"  confidence=91

          ↓ reconcile

winner: "张珊"
reason: confirmed human value outranks unconfirmed candidates
```

## Project boundary

SourceFuse is **not** an HTTP client, API testing tool, mock server, VCR, OpenAPI validator, workflow engine, database merge system, or LLM agent framework.

The first release focuses on pure MoonBit reconciliation logic. In v0.1,
candidate values are textual `String` fields; callers should canonicalize
domain-specific numbers, dates, identifiers, or enums before reconciliation.

- candidate/source model
- authority and confidence policy
- confirmed/locked semantics
- deterministic conflict detection
- decision traces
- reproducible tests

See [docs/PROJECT_SCOPE.md](docs/PROJECT_SCOPE.md).

## Policy example

```moonbit
let policy = @sourcefuse.policy(
  @sourcefuse.AsciiTrimCaseFold,
  true,
  [@sourcefuse.AuthorityRank, @sourcefuse.ConfidenceRank],
  [
    @sourcefuse.source_authority(@sourcefuse.Human, 100),
    @sourcefuse.source_authority(@sourcefuse.Device, 80),
    @sourcefuse.source_authority(@sourcefuse.Model, 20),
  ],
)

let result = @sourcefuse.reconcile_with_policy(candidates, policy)
```

The resolved value is canonicalized by the selected normalization mode, while
the original candidate values remain available in provenance. `supporter_count`
is explanatory only: SourceFuse does not use source count as a voting rule.

## Status

Gate 1 complete — deterministic reconciliation core.

Gate 2 complete — normalization and configurable policy.

Gate 3 complete — structured multi-field reconciliation and decision reports.

Gate 4 complete — versioned JSON wire schemas and adapters.

Gate 4.5 complete — provenance-preserving decision reports, semantic regression
guards, and cross-target CI hardening.

Gate 5 complete — runnable examples, native reference CLI, quickstart, and
evaluation-oriented documentation.

Gate 6 complete — explicit public API contract, package/release checks,
changelog, and v0.1.0 release hardening.

## Architecture

```text
typed candidates ──> core/ ──> DecisionReport ──> wire/ ──> JSON
                                               │
                                               └── cmd/sourcefuse
                                                   native reference adapter
```

The reusable reconciliation engine remains independent of file IO, command-line
parsing, HTTP, databases, system time, and AI services.

## License

Apache-2.0


## JSON wire example

```json
{
  "schema_version": "sourcefuse.record.v1",
  "default_policy": {
    "normalization": "ascii_trim_case_fold",
    "rank_order": ["authority", "confidence", "revision"]
  },
  "fields": [
    {
      "name": "name",
      "candidates": [
        {
          "value": " 张珊 ",
          "source_id": "operator",
          "source_kind": "human",
          "authority": 100,
          "confidence": 100,
          "revision": 2,
          "state": "confirmed"
        }
      ]
    }
  ]
}
```

Parse and reconcile without adding JSON concerns to the core package:

```moonbit
match @wire.reconcile_record_json(text, pretty=true) {
  Ok(report_json) => println(report_json)
  Err(error) => println(error.message)
}
```

The decision-report wire output includes both `considered` and `supporters`
candidate arrays, so the rule trace can be audited against the original
source evidence rather than only aggregate counts.

See [docs/WIRE_SCHEMA.md](docs/WIRE_SCHEMA.md), [docs/API.md](docs/API.md),
[docs/CLI.md](docs/CLI.md), [docs/EVALUATION.md](docs/EVALUATION.md), and
[examples/README.md](examples/README.md).

Release history is in [CHANGELOG.md](CHANGELOG.md); the release procedure is in
[docs/RELEASE.md](docs/RELEASE.md).
