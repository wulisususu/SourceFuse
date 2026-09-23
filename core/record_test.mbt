///|
fn r_candidate(
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
test "record reconciles independent fields and preserves declaration order" {
  let result = @core.reconcile_record(
    @core.record([
      @core.field("name", [
        r_candidate("张珊", "human", @core.Human, 100, 100, 2, @core.Confirmed),
        r_candidate("张山", "model", @core.Model, 10, 95, 3, @core.Proposed),
      ]),
      @core.field("id_number", [
        r_candidate("3201", "card", @core.Device, 90, 99, 1, @core.Proposed),
        r_candidate("3201", "ocr", @core.Model, 30, 98, 1, @core.Proposed),
      ]),
    ]),
  )
  assert_eq(result.status, @core.RecordReconciled)
  assert_eq(result.resolved_count, 2)
  assert_eq(result.conflict_count, 0)
  assert_eq(result.fields[0].field_name, "name")
  assert_eq(result.fields[1].field_name, "id_number")
  assert_eq(result.fields[0].result.value, Some("张珊"))
  assert_eq(result.fields[1].result.value, Some("3201"))
  assert_true(@core.record_fully_resolved(result))
}

///|
test "one conflicted field does not prevent other fields from resolving" {
  let result = @core.reconcile_record(
    @core.record([
      @core.field("name", [
        r_candidate("Alice", "human", @core.Human, 100, 100, 1, @core.Locked),
      ]),
      @core.field("phone", [
        r_candidate("138", "left", @core.Rule, 50, 90, 1, @core.Proposed),
        r_candidate("139", "right", @core.Rule, 50, 90, 1, @core.Proposed),
      ]),
      @core.field("city", [
        r_candidate("Nanjing", "crm", @core.External, 50, 80, 1, @core.Proposed),
      ]),
    ]),
  )
  assert_eq(result.resolved_count, 2)
  assert_eq(result.conflict_count, 1)
  assert_eq(result.fields[0].result.value, Some("Alice"))
  assert_eq(result.fields[1].result.status, @core.Conflict)
  assert_eq(result.fields[2].result.value, Some("Nanjing"))
  assert_false(@core.record_fully_resolved(result))
}

///|
test "field policy override wins over record default policy" {
  let default = @core.policy(
    @core.Exact,
    true,
    [@core.AuthorityRank, @core.ConfidenceRank],
    [],
  )
  let phone_policy = @core.policy(
    @core.Exact,
    false,
    [@core.ConfidenceRank, @core.AuthorityRank],
    [],
  )
  let result = @core.reconcile_record(
    @core.record_with_policy(
      [
        @core.field("name", [
          r_candidate("human", "h", @core.Human, 100, 10, 1, @core.Proposed),
          r_candidate("model", "m", @core.Model, 10, 99, 1, @core.Proposed),
        ]),
        @core.field_with_policy("phone", [
          r_candidate("authority", "a", @core.External, 100, 10, 1, @core.Proposed),
          r_candidate("confidence", "b", @core.External, 10, 99, 1, @core.Proposed),
        ], phone_policy),
      ],
      default,
    ),
  )
  assert_eq(result.fields[0].result.value, Some("human"))
  assert_eq(result.fields[1].result.value, Some("confidence"))
}

///|
test "duplicate field names reject whole record before arbitration" {
  let result = @core.reconcile_record(
    @core.record([
      @core.field("name", [
        r_candidate("A", "one", @core.Human, 1, 1, 1, @core.Proposed),
      ]),
      @core.field("name", [
        r_candidate("B", "two", @core.Human, 1, 1, 1, @core.Proposed),
      ]),
    ]),
  )
  assert_eq(result.status, @core.RecordInvalid)
  assert_eq(result.fields.length(), 0)
  assert_eq(result.resolved_count, 0)
  assert_eq(result.conflict_count, 0)
  assert_eq(result.issues, [@core.DuplicateFieldName("name")])
}

///|
test "duplicate issue list is stable and reports each duplicate once" {
  let result = @core.reconcile_record(
    @core.record([
      @core.field("a", []),
      @core.field("b", []),
      @core.field("a", []),
      @core.field("a", []),
      @core.field("b", []),
    ]),
  )
  assert_eq(
    result.issues,
    [@core.DuplicateFieldName("a"), @core.DuplicateFieldName("b")],
  )
}

///|
test "decision report summarizes field results without losing traces" {
  let result = @core.reconcile_record(
    @core.record([
      @core.field("name", [
        r_candidate(" Alice ", "human", @core.Human, 100, 90, 1, @core.Proposed),
        r_candidate("alice", "model", @core.Model, 100, 90, 1, @core.Proposed),
      ]),
      @core.field("phone", [
        r_candidate("138", "left", @core.Rule, 50, 90, 1, @core.Proposed),
        r_candidate("139", "right", @core.Rule, 50, 90, 1, @core.Proposed),
      ]),
    ]),
  )
  let report = @core.decision_report(result)
  assert_eq(report.declared_fields, 2)
  assert_eq(report.resolved_fields, 0)
  assert_eq(report.conflicted_fields, 2)
  assert_eq(report.fields[0].field_name, "name")
  assert_true(report.fields[0].trace.length() > 0)
  assert_eq(report.fields[0].considered.length(), 2)
  assert_eq(report.fields[0].considered[0].source_id, "human")
  assert_eq(report.fields[1].candidate_count, 2)
  assert_eq(report.fields[1].considered.length(), 2)
  assert_eq(report.fields[1].supporters.length(), 0)
}

///|
test "decision report preserves normalized field resolution summary" {
  let normalized = @core.policy(
    @core.AsciiTrimCaseFold,
    true,
    [@core.AuthorityRank, @core.ConfidenceRank],
    [],
  )
  let result = @core.reconcile_record(
    @core.record_with_policy(
      [
        @core.field("name", [
          r_candidate(" Alice ", "human", @core.Human, 100, 90, 1, @core.Proposed),
          r_candidate("alice", "model", @core.Model, 100, 90, 1, @core.Proposed),
        ]),
      ],
      normalized,
    ),
  )
  let report = @core.decision_report(result)
  assert_eq(report.resolved_fields, 1)
  assert_eq(report.conflicted_fields, 0)
  assert_eq(report.fields[0].value, Some("alice"))
  assert_eq(report.fields[0].supporter_count, 2)
  assert_eq(report.fields[0].considered.length(), 2)
  assert_eq(report.fields[0].supporters.length(), 2)
  assert_eq(report.fields[0].supporters[0].value, " Alice ")
  assert_eq(report.fields[0].supporters[1].source_id, "model")
}

///|
test "empty record is valid and fully resolved" {
  let result = @core.reconcile_record(@core.record([]))
  assert_eq(result.status, @core.RecordReconciled)
  assert_eq(result.declared_count, 0)
  assert_eq(result.resolved_count, 0)
  assert_eq(result.conflict_count, 0)
  assert_true(@core.record_fully_resolved(result))
}
