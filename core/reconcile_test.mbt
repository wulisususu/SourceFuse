///|
fn c(
  value : String,
  source_id : String,
  source_kind : @sourcefuse.SourceKind,
  authority : Int,
  confidence : Int,
  revision : Int,
  state : @sourcefuse.CandidateState,
) -> @sourcefuse.Candidate {
  @sourcefuse.candidate(
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
test "empty input is an explicit conflict" {
  let result = @sourcefuse.reconcile([])
  assert_eq(result.status, @sourcefuse.Conflict)
  assert_eq(result.value, None)
  assert_eq(result.conflict, Some(@sourcefuse.EmptyInput))
  assert_eq(result.trace[0].rule, @sourcefuse.EmptyCandidates)
}

///|
test "locked value cannot be replaced by higher confidence proposal" {
  let result = @sourcefuse.reconcile([
    c("张珊", "human", @sourcefuse.Human, 10, 80, 1, @sourcefuse.Locked),
    c("张山", "model", @sourcefuse.Model, 100, 100, 99, @sourcefuse.Proposed),
  ])
  assert_eq(result.status, @sourcefuse.Resolved)
  assert_eq(result.value, Some("张珊"))
  assert_eq(result.supporters.length(), 1)
  assert_eq(result.trace[0].rule, @sourcefuse.LockedValue)
}

///|
test "conflicting locked values never silently pick array order" {
  let result = @sourcefuse.reconcile([
    c("A", "left", @sourcefuse.Human, 10, 90, 1, @sourcefuse.Locked),
    c("B", "right", @sourcefuse.Human, 10, 90, 1, @sourcefuse.Locked),
  ])
  assert_eq(result.status, @sourcefuse.Conflict)
  assert_eq(result.value, None)
  assert_eq(result.conflict, Some(@sourcefuse.LockedConflict))
}

///|
test "confirmed candidate outranks stronger ordinary proposal" {
  let result = @sourcefuse.reconcile([
    c("confirmed", "human", @sourcefuse.Human, 1, 10, 1, @sourcefuse.Confirmed),
    c("proposal", "model", @sourcefuse.Model, 100, 100, 100, @sourcefuse.Proposed),
  ])
  assert_eq(result.value, Some("confirmed"))
  assert_eq(result.trace[0].rule, @sourcefuse.ConfirmedDominates)
}

///|
test "authority outranks confidence" {
  let result = @sourcefuse.reconcile([
    c("device", "card-reader", @sourcefuse.Device, 100, 40, 1, @sourcefuse.Proposed),
    c("model", "llm", @sourcefuse.Model, 50, 99, 1, @sourcefuse.Proposed),
  ])
  assert_eq(result.value, Some("device"))
  assert_eq(result.trace[0].rule, @sourcefuse.HigherAuthority)
}

///|
test "confidence breaks equal-authority tie" {
  let result = @sourcefuse.reconcile([
    c("A", "ocr-a", @sourcefuse.Model, 50, 80, 1, @sourcefuse.Proposed),
    c("B", "ocr-b", @sourcefuse.Model, 50, 95, 1, @sourcefuse.Proposed),
  ])
  assert_eq(result.value, Some("B"))
  assert_eq(result.trace[0].rule, @sourcefuse.HigherConfidence)
}

///|
test "revision breaks equal authority and confidence tie" {
  let result = @sourcefuse.reconcile([
    c("old", "system", @sourcefuse.External, 50, 90, 2, @sourcefuse.Proposed),
    c("new", "system", @sourcefuse.External, 50, 90, 3, @sourcefuse.Proposed),
  ])
  assert_eq(result.value, Some("new"))
  assert_eq(result.trace[0].rule, @sourcefuse.NewerRevision)
}

///|
test "different values with exact same rank become conflict" {
  let result = @sourcefuse.reconcile([
    c("A", "left", @sourcefuse.Rule, 50, 90, 2, @sourcefuse.Proposed),
    c("B", "right", @sourcefuse.Rule, 50, 90, 2, @sourcefuse.Proposed),
  ])
  assert_eq(result.status, @sourcefuse.Conflict)
  assert_eq(result.conflict, Some(@sourcefuse.EqualPriorityConflict))
  assert_eq(
    result.trace[result.trace.length() - 1].rule,
    @sourcefuse.EqualPriorityValuesConflict,
  )
}

///|
test "same tied value resolves and preserves all supporting provenance" {
  let result = @sourcefuse.reconcile([
    c("张珊", "ocr", @sourcefuse.Model, 50, 98, 2, @sourcefuse.Proposed),
    c("张珊", "rule", @sourcefuse.Rule, 50, 98, 2, @sourcefuse.Proposed),
    c("张山", "other", @sourcefuse.Model, 10, 99, 9, @sourcefuse.Proposed),
  ])
  assert_eq(result.status, @sourcefuse.Resolved)
  assert_eq(result.value, Some("张珊"))
  assert_eq(result.supporters.length(), 2)
  assert_eq(result.considered.length(), 3)
}
