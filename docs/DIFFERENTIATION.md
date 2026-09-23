# Design differentiation

SourceFuse is intentionally narrower than several adjacent problem categories.
That narrowness is part of the library contract.

## Deterministic arbitration, not majority voting

SourceFuse does not choose the most common value. Candidate multiplicity is not
a rank dimension. Multiple low-priority candidates cannot outvote a locked,
confirmed, or higher-authority candidate merely by being numerous.

`supporter_count` is computed after reconciliation and exists for explanation.

## Deterministic arbitration, not probabilistic truth discovery

Confidence is a caller-provided integer rank signal. SourceFuse does not learn
source reliability, estimate posterior truth probabilities, or infer latent
ground truth.

This makes decisions reproducible and suitable for applications that already
have explicit authority rules.

## Conflict reporting, not arbitrary tie-breaking

If different normalized values remain equally ranked after every configured
dimension, SourceFuse returns `EqualPriorityConflict`.

Input array order is deliberately not used as an implicit final tie-breaker.

## Provenance, not lossy field merging

A resolved value does not erase the evidence that produced it. The result keeps
all considered candidates and the candidates whose normalized values support
the resolved canonical value.

This allows downstream systems to explain or audit a decision without
reconstructing source data.

## Policy engine, not workflow engine

SourceFuse decides which candidate value wins for a logical field. It does not
schedule tasks, call APIs, retry services, persist workflows, or orchestrate
agents.

Applications can embed SourceFuse inside those systems without the library
taking ownership of their runtime.

## Record reconciliation, not entity resolution

Fields in a `RecordInput` are already declared to represent the same logical
record. SourceFuse does not decide whether two unrelated people, devices, or
database rows represent the same real-world entity.

## Why the boundary matters

The narrow contract keeps the core:

- deterministic;
- testable without infrastructure;
- portable across MoonBit backends;
- reusable from applications with very different runtime architectures;
- explainable through stable decision rules and provenance.
