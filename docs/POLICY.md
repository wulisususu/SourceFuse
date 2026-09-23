# Reconciliation Policy

SourceFuse separates evidence from policy.

A `Candidate` describes what one source proposed. A `ReconcilePolicy`
describes how an application wants competing candidates compared.

## Default policy

```text
Locked
  ↓
Confirmed
  ↓
Authority
  ↓
Confidence
  ↓
Revision
  ↓
exact tie across different values → Conflict
```

`reconcile(candidates)` is equivalent to:

```moonbit
reconcile_with_policy(candidates, default_policy())
```

## Locked is an invariant

`Locked` is intentionally not configurable.

If at least one locked candidate exists, non-locked candidates cannot replace
it. If locked candidates disagree after normalization, SourceFuse returns
`LockedConflict`.

This prevents a permissive business policy from silently overwriting a value
that another part of the application explicitly marked immutable.

## Normalization

Three built-in modes are available:

| Mode | Behavior |
| --- | --- |
| `Exact` | compare the original strings |
| `AsciiTrim` | trim surrounding whitespace |
| `AsciiTrimCaseFold` | trim, then lowercase ASCII characters |

Case folding is deliberately ASCII-only in v0.1. SourceFuse does not pretend to
perform locale-aware Unicode identity matching.

Normalization changes equality and the canonical resolved value, but it does
not rewrite provenance:

```text
candidate A original: " API "
candidate B original: "api"

AsciiTrimCaseFold
        ↓

resolved value: "api"
supporters:
  - original " API "
  - original "api"
```

## Ranking order

`rank_order` is an explicit list of dimensions:

- `AuthorityRank`
- `ConfidenceRank`
- `RevisionRank`

Their order is policy.

For example:

```moonbit
[
  ConfidenceRank,
  AuthorityRank,
]
```

means confidence is considered before authority.

Omitting a dimension disables it. An empty rank order is valid: unequal values
will remain unresolved unless Locked/Confirmed handling or normalization already
produces one value.

## Confirmed values

`confirmed_dominates=true` means Confirmed candidates are filtered before
ordinary ranking.

Setting it to `false` keeps Confirmed and Proposed candidates in the same
ranking pool.

This setting never weakens Locked semantics.

## SourceKind authority overrides

Applications can assign broad authority by source kind:

```moonbit
[
  source_authority(Human, 100),
  source_authority(Device, 80),
  source_authority(Rule, 60),
  source_authority(Model, 20),
]
```

When an override exists, it replaces the individual candidate's `authority`
for `AuthorityRank`.

If the same SourceKind appears more than once in the override list, the highest
declared authority is used. This keeps duplicate configuration deterministic
regardless of override ordering.

A SourceKind without an override continues to use the candidate's own
`authority`.

## Revision is not wall-clock time

`revision` is supplied by the caller. SourceFuse does not read the system
clock.

It may represent:

- a database revision;
- event sequence number;
- model pass number;
- user edit version;
- source-specific monotonic counter.

This avoids coupling the core library to operating-system time APIs and makes
tests reproducible.

## DecisionTrace

Policy actions remain visible in the result trace, including:

- value normalization;
- Confirmed filtering;
- SourceKind authority overrides;
- authority/confidence/revision filtering;
- final resolution or unresolved conflict.

The trace explains the decision without discarding the original candidates.
