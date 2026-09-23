///|
/// Candidate set for one logical field.
///
/// policy = None uses the record-level default policy.
pub(all) struct FieldInput {
  name : String
  candidates : Array[Candidate]
  policy : ReconcilePolicy?
} derive(Eq, @debug.Debug)

pub extend FieldInput with Eq::{not_equal, equal}
pub extend FieldInput with @debug.Debug::{to_repr}

///|
/// Construct a field using the record's default policy.
pub fn field(
  name : String,
  candidates : Array[Candidate],
) -> FieldInput {
  { name, candidates, policy: None }
}

///|
/// Construct a field with its own policy override.
pub fn field_with_policy(
  name : String,
  candidates : Array[Candidate],
  policy : ReconcilePolicy,
) -> FieldInput {
  { name, candidates, policy: Some(policy) }
}

///|
/// A structured set of fields reconciled independently.
pub(all) struct RecordInput {
  fields : Array[FieldInput]
  default_policy : ReconcilePolicy
} derive(Eq, @debug.Debug)

pub extend RecordInput with Eq::{not_equal, equal}
pub extend RecordInput with @debug.Debug::{to_repr}

///|
/// Construct a record with SourceFuse's default field policy.
pub fn record(fields : Array[FieldInput]) -> RecordInput {
  { fields, default_policy: default_policy() }
}

///|
/// Construct a record with an explicit default field policy.
pub fn record_with_policy(
  fields : Array[FieldInput],
  default_policy : ReconcilePolicy,
) -> RecordInput {
  { fields, default_policy }
}

///|
/// Record-level validation issues.
pub(all) enum RecordIssue {
  DuplicateFieldName(String)
} derive(Eq, @debug.Debug)

pub extend RecordIssue with Eq::{not_equal, equal}
pub extend RecordIssue with @debug.Debug::{to_repr}

///|
/// Whether record reconciliation was performed.
pub(all) enum RecordStatus {
  RecordReconciled
  RecordInvalid
} derive(Eq, @debug.Debug)

pub extend RecordStatus with Eq::{not_equal, equal}
pub extend RecordStatus with @debug.Debug::{to_repr}

///|
/// Result for one declared field.
pub(all) struct FieldResult {
  field_name : String
  result : ReconcileResult
} derive(Eq, @debug.Debug)

pub extend FieldResult with Eq::{not_equal, equal}
pub extend FieldResult with @debug.Debug::{to_repr}

///|
/// Aggregate result for a structured record.
pub(all) struct RecordResult {
  status : RecordStatus
  declared_count : Int
  resolved_count : Int
  conflict_count : Int
  fields : Array[FieldResult]
  issues : Array[RecordIssue]
} derive(Eq, @debug.Debug)

pub extend RecordResult with Eq::{not_equal, equal}
pub extend RecordResult with @debug.Debug::{to_repr}
