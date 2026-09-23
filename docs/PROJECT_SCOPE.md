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

## v0.1 value domain

The v0.1 core reconciles textual `String` field values. Applications with
numeric, date, identifier, enum, or structured domain values should convert
them to a stable textual canonical form before creating candidates. Typed value
families are intentionally outside the v0.1 contract.

## v0.1 invariants

1. Same input candidates + same policy must always produce the same result.
2. A locked value cannot be silently replaced.
3. Conflicting locked values must produce an unresolved conflict.
4. Confirmed values outrank ordinary proposals by default; an explicit policy may disable that precedence.
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

Candidate multiplicity is not a ranking dimension in v0.1. `supporter_count`
reports corroborating evidence after a decision; it does not implement majority
voting or probabilistic truth discovery.

Decision traces are audited together with provenance: every field report keeps
the complete considered candidates plus the candidates supporting the resolved
canonical value.

## Gate plan

- Gate 0: ✅ scope, invariants, competition differentiation.
- Gate 1: ✅ candidate/source/result model + deterministic core.
- Gate 2: ✅ normalization + configurable reconciliation policy.
- Gate 3: ✅ structured multi-field reconciliation, record conflicts, decision reports.
- Gate 4: ✅ stable v1 JSON wire schemas, structured parse errors, and adapter boundary.
- Gate 4.5: ✅ provenance-preserving reports, semantic regression guards, and cross-target CI.
- Gate 5: ✅ runnable examples, native reference CLI, and evaluation documentation.
- Gate 6: next — submission hardening and release packaging.
