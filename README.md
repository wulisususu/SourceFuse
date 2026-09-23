# SourceFuse

A deterministic multi-source value arbitration library for MoonBit.

SourceFuse answers one narrow question:

> When multiple sources propose different values for the same field, which value should win, and why?

Typical sources include humans, devices, rules, models, and external systems. The core library produces a deterministic decision plus an explainable decision trace.

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

The first release focuses on pure MoonBit reconciliation logic:

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
the original candidate values remain available in provenance.

## Status

Gate 1 complete — deterministic reconciliation core.

Gate 2 complete — normalization and configurable policy.

Gate 3 in progress — structured multi-field reconciliation and decision reports.

## License

Apache-2.0
