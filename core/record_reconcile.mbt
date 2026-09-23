///|
fn contains_string(values : Array[String], value : String) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
fn duplicate_field_names(fields : Array[FieldInput]) -> Array[String] {
  let seen : Array[String] = []
  let duplicates : Array[String] = []
  for field in fields {
    if contains_string(seen, field.name) {
      if !contains_string(duplicates, field.name) {
        duplicates.push(field.name)
      }
    } else {
      seen.push(field.name)
    }
  }
  duplicates
}

///|
fn effective_field_policy(
  field : FieldInput,
  default : ReconcilePolicy,
) -> ReconcilePolicy {
  match field.policy {
    Some(policy) => policy
    None => default
  }
}

///|
/// Reconcile every field independently in declaration order.
///
/// Duplicate logical field names invalidate the whole record because a caller
/// could not unambiguously address the resulting field decisions.
pub fn reconcile_record(input : RecordInput) -> RecordResult {
  let duplicates = duplicate_field_names(input.fields)
  if duplicates.length() > 0 {
    let issues : Array[RecordIssue] = []
    for name in duplicates {
      issues.push(DuplicateFieldName(name))
    }
    return {
      status: RecordInvalid,
      declared_count: input.fields.length(),
      resolved_count: 0,
      conflict_count: 0,
      fields: [],
      issues,
    }
  }

  let results : Array[FieldResult] = []
  let mut resolved_count = 0
  let mut conflict_count = 0

  for field in input.fields {
    let result = reconcile_with_policy(
      field.candidates,
      effective_field_policy(field, input.default_policy),
    )
    match result.status {
      Resolved => resolved_count = resolved_count + 1
      Conflict => conflict_count = conflict_count + 1
    }
    results.push({ field_name: field.name, result })
  }

  {
    status: RecordReconciled,
    declared_count: input.fields.length(),
    resolved_count,
    conflict_count,
    fields: results,
    issues: [],
  }
}

///|
/// True only when the record was valid and every declared field resolved.
pub fn record_fully_resolved(result : RecordResult) -> Bool {
  result.status == RecordReconciled &&
  result.conflict_count == 0 &&
  result.resolved_count == result.declared_count
}
