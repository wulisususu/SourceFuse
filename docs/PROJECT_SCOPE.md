# Project Scope

## One-sentence definition

SourceFuse is a deterministic MoonBit library for reconciling conflicting candidate values for the same logical field while preserving source provenance and a machine-readable explanation of the decision.

## Core problem

Applications increasingly receive the same fact from multiple sources:

- a human correction;
- a device or sensor;
- a deterministic rule;
- an AI model;
- an external system.

Those sources can disagree. Choosing the largest confidence score is insufficient because source authority, explicit confirmation, locks, and ties may matter more than confidence.

SourceFuse turns this into an explicit data model and deterministic policy engine.

## v0.1 invariants

1. Same input candidates + same policy must always produce the same result.
2. A locked value cannot be silently replaced.
3. Conflicting locked values must produce an unresolved conflict.
4. Confirmed values outrank ordinary proposals unless policy explicitly changes this in a future version.
5. Confidence is a tie-break signal, not universal truth.
6. Every resolved or unresolved decision must preserve source provenance.
7. The engine must emit a decision trace sufficient to explain the applied rules.
8. Core logic must not depend on HTTP, async, wall-clock time, databases, file systems, or AI services.

## Explicit non-goals

SourceFuse does not implement:

- HTTP/API debugging or testing;
- OpenAPI contract validation;
- HTTP mocking or record/replay;
- workflow orchestration;
- CRDT/network replication;
- database synchronization;
- entity resolution across unrelated records;
- probabilistic truth discovery;
- LLM prompting or agent orchestration.

## v0.1 policy order

Initial deterministic precedence:

1. locked candidates;
2. confirmed candidates;
3. source authority;
4. confidence;
5. caller-provided revision;
6. if different values remain exactly tied, return an unresolved conflict rather than selecting arbitrarily.

No system clock is used. `revision` is supplied by the caller.

## Gate plan

- Gate 0: ✅ scope, invariants, competition differentiation.
- Gate 1: ✅ candidate/source/result model + deterministic core.
- Gate 2: ✅ normalization + configurable reconciliation policy.
- Gate 3: next — richer conflicts, batch/field reconciliation, decision trace reporting.
- Gate 4: application adapters and serialization.
- Gate 5: examples, CLI/demo adapter, documentation.
- Gate 6: cross-target CI and submission hardening.
