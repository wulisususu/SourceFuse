///|
fn copy_candidates(candidates : Array[Candidate]) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    out.push(candidate)
  }
  out
}

///|
fn candidates_with_state(
  candidates : Array[Candidate],
  state : CandidateState,
) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    if candidate.state == state {
      out.push(candidate)
    }
  }
  out
}

///|
fn normalized_candidate_value(
  candidate : Candidate,
  policy : ReconcilePolicy,
) -> String {
  normalize_value(candidate.value, policy.normalization)
}

///|
fn candidates_with_normalized_value(
  candidates : Array[Candidate],
  value : String,
  policy : ReconcilePolicy,
) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    if normalized_candidate_value(candidate, policy) == value {
      out.push(candidate)
    }
  }
  out
}

///|
fn all_same_value(
  candidates : Array[Candidate],
  policy : ReconcilePolicy,
) -> Bool {
  if candidates.length() <= 1 {
    return true
  }
  let first = normalized_candidate_value(candidates[0], policy)
  for candidate in candidates {
    if normalized_candidate_value(candidate, policy) != first {
      return false
    }
  }
  true
}

///|
fn normalization_changed(
  candidates : Array[Candidate],
  policy : ReconcilePolicy,
) -> Bool {
  for candidate in candidates {
    if normalized_candidate_value(candidate, policy) != candidate.value {
      return true
    }
  }
  false
}

///|
fn authority_override_for(
  candidate : Candidate,
  policy : ReconcilePolicy,
) -> Int {
  let mut found = false
  let mut best = 0
  for item in policy.source_authorities {
    if item.source_kind == candidate.source_kind {
      if !found || item.authority > best {
        found = true
        best = item.authority
      }
    }
  }
  if found {
    best
  } else {
    candidate.authority
  }
}

///|
fn has_authority_override(
  candidates : Array[Candidate],
  policy : ReconcilePolicy,
) -> Bool {
  for candidate in candidates {
    for item in policy.source_authorities {
      if item.source_kind == candidate.source_kind {
        return true
      }
    }
  }
  false
}

///|
fn rank_value(
  candidate : Candidate,
  dimension : RankDimension,
  policy : ReconcilePolicy,
) -> Int {
  match dimension {
    AuthorityRank => authority_override_for(candidate, policy)
    ConfidenceRank => candidate.confidence
    RevisionRank => candidate.revision
  }
}

///|
fn max_rank(
  candidates : Array[Candidate],
  dimension : RankDimension,
  policy : ReconcilePolicy,
) -> Int {
  let mut best = rank_value(candidates[0], dimension, policy)
  for candidate in candidates {
    let current = rank_value(candidate, dimension, policy)
    if current > best {
      best = current
    }
  }
  best
}

///|
fn keep_rank(
  candidates : Array[Candidate],
  dimension : RankDimension,
  value : Int,
  policy : ReconcilePolicy,
) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    if rank_value(candidate, dimension, policy) == value {
      out.push(candidate)
    }
  }
  out
}

///|
fn rank_rule(dimension : RankDimension) -> DecisionRule {
  match dimension {
    AuthorityRank => HigherAuthority
    ConfidenceRank => HigherConfidence
    RevisionRank => NewerRevision
  }
}

///|
fn rank_detail(dimension : RankDimension) -> String {
  match dimension {
    AuthorityRank => "lower-authority candidates were removed"
    ConfidenceRank => "lower-confidence candidates were removed"
    RevisionRank => "older candidate revisions were removed"
  }
}

///|
fn resolved_result(
  considered : Array[Candidate],
  value : String,
  policy : ReconcilePolicy,
  trace : Array[DecisionStep],
) -> ReconcileResult {
  trace.push({
    rule: ResolvedValue,
    detail: "one deterministic normalized value remained after reconciliation",
  })
  {
    status: Resolved,
    value: Some(value),
    conflict: None,
    considered: copy_candidates(considered),
    supporters: candidates_with_normalized_value(considered, value, policy),
    trace,
  }
}

///|
fn conflict_result(
  considered : Array[Candidate],
  conflict : ConflictKind,
  trace : Array[DecisionStep],
) -> ReconcileResult {
  {
    status: Conflict,
    value: None,
    conflict: Some(conflict),
    considered: copy_candidates(considered),
    supporters: [],
    trace,
  }
}

///|
/// Reconcile candidate values using the stable default policy.
///
/// This preserves the Gate 1 precedence:
/// locked -> confirmed -> authority -> confidence -> revision.
pub fn reconcile(candidates : Array[Candidate]) -> ReconcileResult {
  reconcile_with_policy(candidates, default_policy())
}

///|
/// Reconcile candidates under an explicit deterministic policy.
///
/// Locked values remain a non-configurable safety invariant. Normalization is
/// applied only for comparison and the resolved canonical value; every
/// original Candidate is retained in considered/supporters provenance.
pub fn reconcile_with_policy(
  candidates : Array[Candidate],
  policy : ReconcilePolicy,
) -> ReconcileResult {
  let trace : Array[DecisionStep] = []

  if candidates.length() == 0 {
    trace.push({
      rule: EmptyCandidates,
      detail: "no candidate values were provided",
    })
    return conflict_result(candidates, EmptyInput, trace)
  }

  if normalization_changed(candidates, policy) {
    trace.push({
      rule: ValuesNormalized,
      detail: "candidate values were canonicalized before equality checks",
    })
  }

  let locked = candidates_with_state(candidates, Locked)
  if locked.length() > 0 {
    if !all_same_value(locked, policy) {
      trace.push({
        rule: LockedValuesConflict,
        detail: "locked candidates disagree after normalization and cannot be silently replaced",
      })
      return conflict_result(candidates, LockedConflict, trace)
    }
    trace.push({
      rule: LockedValue,
      detail: "a locked value outranks every non-locked candidate",
    })
    return resolved_result(
      candidates,
      normalized_candidate_value(locked[0], policy),
      policy,
      trace,
    )
  }

  let confirmed = candidates_with_state(candidates, Confirmed)
  let mut pool = if policy.confirmed_dominates && confirmed.length() > 0 {
    trace.push({
      rule: ConfirmedDominates,
      detail: "confirmed candidates outrank ordinary proposals under this policy",
    })
    confirmed
  } else {
    copy_candidates(candidates)
  }

  for dimension in policy.rank_order {
    if dimension == AuthorityRank && has_authority_override(pool, policy) {
      trace.push({
        rule: SourceAuthorityOverrideApplied,
        detail: "SourceKind authority overrides were applied for authority ranking",
      })
    }

    let best = max_rank(pool, dimension, policy)
    let next = keep_rank(pool, dimension, best, policy)
    if next.length() < pool.length() {
      trace.push({
        rule: rank_rule(dimension),
        detail: rank_detail(dimension),
      })
    }
    pool = next
  }

  if all_same_value(pool, policy) {
    return resolved_result(
      candidates,
      normalized_candidate_value(pool[0], policy),
      policy,
      trace,
    )
  }

  trace.push({
    rule: EqualPriorityValuesConflict,
    detail: "different normalized values remain exactly tied; input order is not a tie-breaker",
  })
  conflict_result(candidates, EqualPriorityConflict, trace)
}
