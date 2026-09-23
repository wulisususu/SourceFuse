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
fn candidates_with_value(
  candidates : Array[Candidate],
  value : String,
) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    if candidate.value == value {
      out.push(candidate)
    }
  }
  out
}

///|
fn all_same_value(candidates : Array[Candidate]) -> Bool {
  if candidates.length() <= 1 {
    return true
  }
  let first = candidates[0].value
  for candidate in candidates {
    if candidate.value != first {
      return false
    }
  }
  true
}

///|
fn max_authority(candidates : Array[Candidate]) -> Int {
  let mut best = candidates[0].authority
  for candidate in candidates {
    if candidate.authority > best {
      best = candidate.authority
    }
  }
  best
}

///|
fn keep_authority(
  candidates : Array[Candidate],
  authority : Int,
) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    if candidate.authority == authority {
      out.push(candidate)
    }
  }
  out
}

///|
fn max_confidence(candidates : Array[Candidate]) -> Int {
  let mut best = candidates[0].confidence
  for candidate in candidates {
    if candidate.confidence > best {
      best = candidate.confidence
    }
  }
  best
}

///|
fn keep_confidence(
  candidates : Array[Candidate],
  confidence : Int,
) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    if candidate.confidence == confidence {
      out.push(candidate)
    }
  }
  out
}

///|
fn max_revision(candidates : Array[Candidate]) -> Int {
  let mut best = candidates[0].revision
  for candidate in candidates {
    if candidate.revision > best {
      best = candidate.revision
    }
  }
  best
}

///|
fn keep_revision(
  candidates : Array[Candidate],
  revision : Int,
) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    if candidate.revision == revision {
      out.push(candidate)
    }
  }
  out
}

///|
fn resolved_result(
  considered : Array[Candidate],
  value : String,
  trace : Array[DecisionStep],
) -> ReconcileResult {
  trace.push({
    rule: ResolvedValue,
    detail: "one deterministic value remained after reconciliation",
  })
  {
    status: Resolved,
    value: Some(value),
    conflict: None,
    considered: copy_candidates(considered),
    supporters: candidates_with_value(considered, value),
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
/// Reconcile candidate values using the v0.1 deterministic precedence:
///
/// locked -> confirmed -> authority -> confidence -> revision.
///
/// Different values that remain exactly tied are reported as a conflict.
/// Input order is never used as a tie-breaker.
pub fn reconcile(candidates : Array[Candidate]) -> ReconcileResult {
  let trace : Array[DecisionStep] = []

  if candidates.length() == 0 {
    trace.push({
      rule: EmptyCandidates,
      detail: "no candidate values were provided",
    })
    return conflict_result(candidates, EmptyInput, trace)
  }

  let locked = candidates_with_state(candidates, Locked)
  if locked.length() > 0 {
    if !all_same_value(locked) {
      trace.push({
        rule: LockedValuesConflict,
        detail: "locked candidates disagree and cannot be silently replaced",
      })
      return conflict_result(candidates, LockedConflict, trace)
    }
    trace.push({
      rule: LockedValue,
      detail: "a locked value outranks every non-locked candidate",
    })
    return resolved_result(candidates, locked[0].value, trace)
  }

  let confirmed = candidates_with_state(candidates, Confirmed)
  let mut pool = if confirmed.length() > 0 {
    trace.push({
      rule: ConfirmedDominates,
      detail: "confirmed candidates outrank ordinary proposals",
    })
    confirmed
  } else {
    copy_candidates(candidates)
  }

  let authority = max_authority(pool)
  let authority_pool = keep_authority(pool, authority)
  if authority_pool.length() < pool.length() {
    trace.push({
      rule: HigherAuthority,
      detail: "lower-authority candidates were removed",
    })
  }
  pool = authority_pool

  let confidence = max_confidence(pool)
  let confidence_pool = keep_confidence(pool, confidence)
  if confidence_pool.length() < pool.length() {
    trace.push({
      rule: HigherConfidence,
      detail: "lower-confidence candidates were removed",
    })
  }
  pool = confidence_pool

  let revision = max_revision(pool)
  let revision_pool = keep_revision(pool, revision)
  if revision_pool.length() < pool.length() {
    trace.push({
      rule: NewerRevision,
      detail: "older candidate revisions were removed",
    })
  }
  pool = revision_pool

  if all_same_value(pool) {
    return resolved_result(candidates, pool[0].value, trace)
  }

  trace.push({
    rule: EqualPriorityValuesConflict,
    detail: "different values remain exactly tied; input order is not a tie-breaker",
  })
  conflict_result(candidates, EqualPriorityConflict, trace)
}
