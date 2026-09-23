///|
/// Compact report entry for one field.
///
/// The report deliberately carries the original considered/supporting
/// candidates so adapters can preserve provenance instead of exposing only
/// aggregate counts.
pub(all) struct FieldDecision {
  field_name : String
  status : ReconcileStatus
  value : String?
  conflict : ConflictKind?
  candidate_count : Int
  supporter_count : Int
  considered : Array[Candidate]
  supporters : Array[Candidate]
  trace : Array[DecisionStep]
} derive(Eq, @debug.Debug)

pub extend FieldDecision with Eq::{not_equal, equal}
pub extend FieldDecision with @debug.Debug::{to_repr}

///|
/// Pure-data summary of a record reconciliation.
pub(all) struct DecisionReport {
  status : RecordStatus
  declared_fields : Int
  resolved_fields : Int
  conflicted_fields : Int
  issues : Array[RecordIssue]
  fields : Array[FieldDecision]
} derive(Eq, @debug.Debug)

pub extend DecisionReport with Eq::{not_equal, equal}
pub extend DecisionReport with @debug.Debug::{to_repr}

///|
fn copy_report_candidates(candidates : Array[Candidate]) -> Array[Candidate] {
  let out : Array[Candidate] = []
  for candidate in candidates {
    out.push(candidate)
  }
  out
}

///|
fn copy_trace(trace : Array[DecisionStep]) -> Array[DecisionStep] {
  let out : Array[DecisionStep] = []
  for step in trace {
    out.push(step)
  }
  out
}

///|
fn copy_issues(issues : Array[RecordIssue]) -> Array[RecordIssue] {
  let out : Array[RecordIssue] = []
  for issue in issues {
    out.push(issue)
  }
  out
}

///|
/// Build a stable report model without performing IO or serialization.
pub fn decision_report(result : RecordResult) -> DecisionReport {
  let fields : Array[FieldDecision] = []
  for field in result.fields {
    fields.push({
      field_name: field.field_name,
      status: field.result.status,
      value: field.result.value,
      conflict: field.result.conflict,
      candidate_count: field.result.considered.length(),
      supporter_count: field.result.supporters.length(),
      considered: copy_report_candidates(field.result.considered),
      supporters: copy_report_candidates(field.result.supporters),
      trace: copy_trace(field.result.trace),
    })
  }
  {
    status: result.status,
    declared_fields: result.declared_count,
    resolved_fields: result.resolved_count,
    conflicted_fields: result.conflict_count,
    issues: copy_issues(result.issues),
    fields,
  }
}
