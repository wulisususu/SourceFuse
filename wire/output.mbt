///|
/// Stable output schema identifier.
pub const DECISION_REPORT_SCHEMA : String = "sourcefuse.decision-report.v1"

///|
fn record_status_text(status : @core.RecordStatus) -> String {
  match status {
    @core.RecordReconciled => "reconciled"
    @core.RecordInvalid => "invalid"
  }
}

///|
fn reconcile_status_text(status : @core.ReconcileStatus) -> String {
  match status {
    @core.Resolved => "resolved"
    @core.Conflict => "conflict"
  }
}

///|
fn conflict_text(conflict : @core.ConflictKind) -> String {
  match conflict {
    @core.EmptyInput => "empty_input"
    @core.LockedConflict => "locked_conflict"
    @core.EqualPriorityConflict => "equal_priority_conflict"
  }
}

///|
fn rule_text(rule : @core.DecisionRule) -> String {
  match rule {
    @core.EmptyCandidates => "empty_candidates"
    @core.LockedValue => "locked_value"
    @core.LockedValuesConflict => "locked_values_conflict"
    @core.ConfirmedDominates => "confirmed_dominates"
    @core.ValuesNormalized => "values_normalized"
    @core.SourceAuthorityOverrideApplied => "source_authority_override_applied"
    @core.HigherAuthority => "higher_authority"
    @core.HigherConfidence => "higher_confidence"
    @core.NewerRevision => "newer_revision"
    @core.EqualPriorityValuesConflict => "equal_priority_values_conflict"
    @core.ResolvedValue => "resolved_value"
  }
}

///|
fn issue_json(issue : @core.RecordIssue) -> Json {
  match issue {
    @core.DuplicateFieldName(name) =>
      Json::object({
        "kind": Json::string("duplicate_field_name"),
        "field_name": Json::string(name),
      })
  }
}

///|
fn trace_json(step : @core.DecisionStep) -> Json {
  Json::object({
    "rule": Json::string(rule_text(step.rule)),
    "detail": Json::string(step.detail),
  })
}

///|
fn field_decision_json(field : @core.FieldDecision) -> Json {
  let trace : Array[Json] = []
  for step in field.trace {
    trace.push(trace_json(step))
  }
  let value = match field.value {
    Some(value) => Json::string(value)
    None => Json::null()
  }
  let conflict = match field.conflict {
    Some(value) => Json::string(conflict_text(value))
    None => Json::null()
  }
  Json::object({
    "name": Json::string(field.field_name),
    "status": Json::string(reconcile_status_text(field.status)),
    "value": value,
    "conflict": conflict,
    "candidate_count": Json::number(field.candidate_count.to_double()),
    "supporter_count": Json::number(field.supporter_count.to_double()),
    "trace": Json::array(trace),
  })
}

///|
/// Serialize a DecisionReport using the stable v1 wire schema.
pub fn decision_report_json(
  report : @core.DecisionReport,
  pretty? : Bool = true,
) -> String {
  let issues : Array[Json] = []
  for issue in report.issues {
    issues.push(issue_json(issue))
  }

  let fields : Array[Json] = []
  for field in report.fields {
    fields.push(field_decision_json(field))
  }

  let json = Json::object({
    "schema_version": Json::string(DECISION_REPORT_SCHEMA),
    "status": Json::string(record_status_text(report.status)),
    "summary": Json::object({
      "declared_fields": Json::number(report.declared_fields.to_double()),
      "resolved_fields": Json::number(report.resolved_fields.to_double()),
      "conflicted_fields": Json::number(report.conflicted_fields.to_double()),
    }),
    "issues": Json::array(issues),
    "fields": Json::array(fields),
  })

  if pretty {
    json.stringify(indent=2)
  } else {
    json.stringify()
  }
}

///|
/// Convenience end-to-end adapter: parse, reconcile, summarize, serialize.
pub fn reconcile_record_json(
  text : String,
  pretty? : Bool = true,
) -> Result[String, WireError] {
  match parse_record_document(text) {
    Err(error) => Err(error)
    Ok(input) => {
      let result = @core.reconcile_record(input)
      let report = @core.decision_report(result)
      Ok(decision_report_json(report, pretty~))
    }
  }
}
