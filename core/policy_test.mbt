///|
fn p_candidate(
  value : String,
  source_id : String,
  source_kind : @core.SourceKind,
  authority : Int,
  confidence : Int,
  revision : Int,
  state : @core.CandidateState,
) -> @core.Candidate {
  @core.candidate(
    value,
    source_id,
    source_kind,
    authority,
    confidence,
    revision,
    state,
  )
}

///|
test "normalization modes are explicit and deterministic" {
  assert_eq(@core.normalize_value(" API ", @core.Exact), " API ")
  assert_eq(@core.normalize_value(" API ", @core.AsciiTrim), "API")
  assert_eq(
    @core.normalize_value(" API ", @core.AsciiTrimCaseFold),
    "api",
  )
  assert_eq(
    @core.normalize_value(" 张珊 ", @core.AsciiTrimCaseFold),
    "张珊",
  )
  assert_eq(
    @core.normalize_value(" Ä Σ API ", @core.AsciiTrimCaseFold),
    "Ä Σ api",
  )
}

///|
test "default exact mode keeps spelling differences as a conflict" {
  let result = @core.reconcile([
    p_candidate("Alice", "left", @core.Rule, 10, 90, 1, @core.Proposed),
    p_candidate(" Alice ", "right", @core.Rule, 10, 90, 1, @core.Proposed),
  ])
  assert_eq(result.status, @core.Conflict)
  assert_eq(result.conflict, Some(@core.EqualPriorityConflict))
}

///|
test "trim mode collapses whitespace-only spelling differences" {
  let policy = @core.policy(
    @core.AsciiTrim,
    true,
    [@core.AuthorityRank, @core.ConfidenceRank, @core.RevisionRank],
    [],
  )
  let result = @core.reconcile_with_policy(
    [
      p_candidate("Alice", "left", @core.Rule, 10, 90, 1, @core.Proposed),
      p_candidate(" Alice ", "right", @core.Rule, 10, 90, 1, @core.Proposed),
    ],
    policy,
  )
  assert_eq(result.status, @core.Resolved)
  assert_eq(result.value, Some("Alice"))
  assert_eq(result.supporters.length(), 2)
  assert_eq(result.supporters[1].value, " Alice ")
  assert_eq(result.trace[0].rule, @core.ValuesNormalized)
}

///|
test "trim and ASCII case fold returns canonical normalized value" {
  let policy = @core.policy(
    @core.AsciiTrimCaseFold,
    true,
    [@core.AuthorityRank, @core.ConfidenceRank, @core.RevisionRank],
    [],
  )
  let result = @core.reconcile_with_policy(
    [
      p_candidate(" API ", "docs", @core.External, 10, 90, 1, @core.Proposed),
      p_candidate("api", "code", @core.External, 10, 90, 1, @core.Proposed),
    ],
    policy,
  )
  assert_eq(result.value, Some("api"))
  assert_eq(result.supporters.length(), 2)
}

///|
test "custom rank order can put confidence before authority" {
  let policy = @core.policy(
    @core.Exact,
    true,
    [@core.ConfidenceRank, @core.AuthorityRank, @core.RevisionRank],
    [],
  )
  let result = @core.reconcile_with_policy(
    [
      p_candidate("high-authority", "device", @core.Device, 100, 30, 1, @core.Proposed),
      p_candidate("high-confidence", "model", @core.Model, 20, 99, 1, @core.Proposed),
    ],
    policy,
  )
  assert_eq(result.value, Some("high-confidence"))
  assert_eq(result.trace[0].rule, @core.HigherConfidence)
}

///|
test "confirmed dominance can be disabled by explicit policy" {
  let policy = @core.policy(
    @core.Exact,
    false,
    [@core.AuthorityRank, @core.ConfidenceRank, @core.RevisionRank],
    [],
  )
  let result = @core.reconcile_with_policy(
    [
      p_candidate("confirmed", "human", @core.Human, 10, 90, 1, @core.Confirmed),
      p_candidate("proposal", "device", @core.Device, 100, 90, 1, @core.Proposed),
    ],
    policy,
  )
  assert_eq(result.value, Some("proposal"))
  assert_eq(result.trace[0].rule, @core.HigherAuthority)
}

///|
test "SourceKind authority override replaces candidate authority" {
  let policy = @core.policy(
    @core.Exact,
    true,
    [@core.AuthorityRank, @core.ConfidenceRank],
    [
      @core.source_authority(@core.Human, 100),
      @core.source_authority(@core.Model, 10),
    ],
  )
  let result = @core.reconcile_with_policy(
    [
      p_candidate("human", "operator", @core.Human, 1, 40, 1, @core.Proposed),
      p_candidate("model", "llm", @core.Model, 999, 100, 1, @core.Proposed),
    ],
    policy,
  )
  assert_eq(result.value, Some("human"))
  assert_eq(result.trace[0].rule, @core.SourceAuthorityOverrideApplied)
  assert_eq(result.trace[1].rule, @core.HigherAuthority)
}

///|
test "locked remains invariant under custom policy" {
  let policy = @core.policy(
    @core.AsciiTrimCaseFold,
    false,
    [@core.RevisionRank, @core.ConfidenceRank],
    [@core.source_authority(@core.Model, 1000)],
  )
  let result = @core.reconcile_with_policy(
    [
      p_candidate("LOCKED", "human", @core.Human, 1, 1, 1, @core.Locked),
      p_candidate("other", "model", @core.Model, 999, 100, 999, @core.Proposed),
    ],
    policy,
  )
  assert_eq(result.value, Some("locked"))
  assert_true(
    result.trace.any(step => step.rule == @core.LockedValue),
  )
}

///|
test "candidate input order never resolves an exact tie" {
  let a = p_candidate("A", "left", @core.Rule, 10, 90, 1, @core.Proposed)
  let b = p_candidate("B", "right", @core.Rule, 10, 90, 1, @core.Proposed)
  let first = @core.reconcile([a, b])
  let second = @core.reconcile([b, a])
  assert_eq(first.status, @core.Conflict)
  assert_eq(second.status, @core.Conflict)
  assert_eq(first.conflict, second.conflict)
  assert_eq(first.value, second.value)
}

///|
test "candidate input order does not change normalized resolution" {
  let policy = @core.policy(
    @core.AsciiTrimCaseFold,
    true,
    [],
    [],
  )
  let a = p_candidate(" API ", "left", @core.Rule, 10, 90, 1, @core.Proposed)
  let b = p_candidate("api", "right", @core.Rule, 10, 90, 1, @core.Proposed)
  let first = @core.reconcile_with_policy([a, b], policy)
  let second = @core.reconcile_with_policy([b, a], policy)
  assert_eq(first.status, @core.Resolved)
  assert_eq(second.status, @core.Resolved)
  assert_eq(first.value, Some("api"))
  assert_eq(second.value, Some("api"))
}

///|
test "empty rank order intentionally leaves unequal values unresolved" {
  let policy = @core.policy(@core.Exact, false, [], [])
  let result = @core.reconcile_with_policy(
    [
      p_candidate("A", "left", @core.Rule, 100, 100, 100, @core.Proposed),
      p_candidate("B", "right", @core.Rule, 1, 1, 1, @core.Proposed),
    ],
    policy,
  )
  assert_eq(result.status, @core.Conflict)
  assert_eq(result.conflict, Some(@core.EqualPriorityConflict))
}
