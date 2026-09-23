///|
fn c(
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
test "empty input is an explicit conflict" {
  let result = @core.reconcile([])
  assert_eq(result.status, @core.Conflict)
  assert_eq(result.value, None)
  assert_eq(result.conflict, Some(@core.EmptyInput))
  assert_eq(result.trace[0].rule, @core.EmptyCandidates)
}

///|
test "locked value cannot be replaced by higher confidence proposal" {
  let result = @core.reconcile([
    c("张珊", "human", @core.Human, 10, 80, 1, @core.Locked),
    c("张山", "model", @core.Model, 100, 100, 99, @core.Proposed),
  ])
  assert_eq(result.status, @core.Resolved)
  assert_eq(result.value, Some("张珊"))
  assert_eq(result.supporters.length(), 1)
  assert_eq(result.trace[0].rule, @core.LockedValue)
}

///|
test "conflicting locked values never silently pick array order" {
  let result = @core.reconcile([
    c("A", "left", @core.Human, 10, 90, 1, @core.Locked),
    c("B", "right", @core.Human, 10, 90, 1, @core.Locked),
  ])
  assert_eq(result.status, @core.Conflict)
  assert_eq(result.value, None)
  assert_eq(result.conflict, Some(@core.LockedConflict))
}

///|
test "confirmed candidate outranks stronger ordinary proposal" {
  let result = @core.reconcile([
    c("confirmed", "human", @core.Human, 1, 10, 1, @core.Confirmed),
    c("proposal", "model", @core.Model, 100, 100, 100, @core.Proposed),
  ])
  assert_eq(result.value, Some("confirmed"))
  assert_eq(result.trace[0].rule, @core.ConfirmedDominates)
}

///|
test "authority outranks confidence" {
  let result = @core.reconcile([
    c("device", "card-reader", @core.Device, 100, 40, 1, @core.Proposed),
    c("model", "llm", @core.Model, 50, 99, 1, @core.Proposed),
  ])
  assert_eq(result.value, Some("device"))
  assert_eq(result.trace[0].rule, @core.HigherAuthority)
}

///|
test "confidence breaks equal-authority tie" {
  let result = @core.reconcile([
    c("A", "ocr-a", @core.Model, 50, 80, 1, @core.Proposed),
    c("B", "ocr-b", @core.Model, 50, 95, 1, @core.Proposed),
  ])
  assert_eq(result.value, Some("B"))
  assert_eq(result.trace[0].rule, @core.HigherConfidence)
}

///|
test "revision breaks equal authority and confidence tie" {
  let result = @core.reconcile([
    c("old", "system", @core.External, 50, 90, 2, @core.Proposed),
    c("new", "system", @core.External, 50, 90, 3, @core.Proposed),
  ])
  assert_eq(result.value, Some("new"))
  assert_eq(result.trace[0].rule, @core.NewerRevision)
}

///|
test "different values with exact same rank become conflict" {
  let result = @core.reconcile([
    c("A", "left", @core.Rule, 50, 90, 2, @core.Proposed),
    c("B", "right", @core.Rule, 50, 90, 2, @core.Proposed),
  ])
  assert_eq(result.status, @core.Conflict)
  assert_eq(result.conflict, Some(@core.EqualPriorityConflict))
  assert_eq(
    result.trace[result.trace.length() - 1].rule,
    @core.EqualPriorityValuesConflict,
  )
}

///|
test "same tied value resolves and preserves all supporting provenance" {
  let result = @core.reconcile([
    c("张珊", "ocr", @core.Model, 50, 98, 2, @core.Proposed),
    c("张珊", "rule", @core.Rule, 50, 98, 2, @core.Proposed),
    c("张山", "other", @core.Model, 10, 99, 9, @core.Proposed),
  ])
  assert_eq(result.status, @core.Resolved)
  assert_eq(result.value, Some("张珊"))
  assert_eq(result.supporters.length(), 2)
  assert_eq(result.considered.length(), 3)
}
