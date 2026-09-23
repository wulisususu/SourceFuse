///|
test "record v1 parses candidates and policy overrides" {
  let text =
    #|{"schema_version":"sourcefuse.record.v1","default_policy":{"normalization":"ascii_trim_case_fold","confirmed_dominates":true,"rank_order":["authority","confidence"],"source_authorities":[{"source_kind":"human","authority":100},{"source_kind":"model","authority":20}]},"fields":[{"name":"name","candidates":[{"value":" Alice ","source_id":"operator","source_kind":"human","authority":1,"confidence":90,"revision":2,"state":"confirmed"},{"value":"alice","source_id":"llm","source_kind":"model","authority":999,"confidence":99,"revision":3,"state":"proposed"}]},{"name":"phone","policy":{"normalization":"exact","confirmed_dominates":false,"rank_order":["confidence","authority"]},"candidates":[{"value":"138","source_id":"human","source_kind":"human","authority":100,"confidence":50,"revision":1,"state":"proposed"},{"value":"139","source_id":"crm","source_kind":"external","authority":10,"confidence":90,"revision":1,"state":"proposed"}]}]}
  match parse_record_document(text) {
    Err(error) => fail(error.message)
    Ok(input) => {
      assert_eq(input.fields.length(), 2)
      assert_eq(input.default_policy.normalization, @core.AsciiTrimCaseFold)
      assert_eq(input.default_policy.rank_order.length(), 2)
      assert_eq(input.fields[0].name, "name")
      assert_eq(input.fields[0].candidates.length(), 2)
      assert_eq(input.fields[0].candidates[0].source_kind, @core.Human)
      assert_eq(input.fields[0].candidates[0].state, @core.Confirmed)
      match input.fields[1].policy {
        None => fail("expected field policy override")
        Some(policy) => {
          assert_false(policy.confirmed_dominates)
          assert_eq(policy.rank_order[0], @core.ConfidenceRank)
        }
      }
    }
  }
}

///|
test "record parser applies default policy when policy objects are omitted" {
  let text =
    #|{"schema_version":"sourcefuse.record.v1","fields":[{"name":"name","candidates":[{"value":"A","source_id":"human","source_kind":"human","authority":10,"confidence":90,"revision":1,"state":"proposed"}]}]}
  match parse_record_document(text) {
    Err(error) => fail(error.message)
    Ok(input) => {
      assert_eq(input.default_policy, @core.default_policy())
      assert_eq(input.fields[0].policy, None)
    }
  }
}

///|
test "malformed JSON returns structured root error" {
  match parse_record_document("{") {
    Ok(_) => fail("expected invalid JSON")
    Err(error) => {
      assert_eq(error.kind, InvalidJson)
      assert_eq(error.path, "$")
      assert_eq(error.message, "document is not valid JSON")
    }
  }
}

///|
test "unknown record schema is rejected before field parsing" {
  let text =
    #|{"schema_version":"sourcefuse.record.v2","fields":[]}
  match parse_record_document(text) {
    Ok(_) => fail("expected unsupported schema")
    Err(error) => {
      assert_eq(error.kind, UnsupportedSchema)
      assert_eq(error.path, "$.schema_version")
      assert_eq(error.message, "unsupported schema version: sourcefuse.record.v2")
    }
  }
}

///|
test "invalid candidate enum reports exact JSON path" {
  let text =
    #|{"schema_version":"sourcefuse.record.v1","fields":[{"name":"name","candidates":[{"value":"A","source_id":"x","source_kind":"robot","authority":1,"confidence":2,"revision":3,"state":"proposed"}]}]}
  match parse_record_document(text) {
    Ok(_) => fail("expected invalid source kind")
    Err(error) => {
      assert_eq(error.kind, InvalidValue)
      assert_eq(error.path, "$.fields[0].candidates[0].source_kind")
    }
  }
}

///|
test "candidate numbers must be integers rather than truncated decimals" {
  let text =
    #|{"schema_version":"sourcefuse.record.v1","fields":[{"name":"name","candidates":[{"value":"A","source_id":"x","source_kind":"human","authority":1.5,"confidence":2,"revision":3,"state":"proposed"}]}]}
  match parse_record_document(text) {
    Ok(_) => fail("expected invalid integer")
    Err(error) => {
      assert_eq(error.kind, InvalidValue)
      assert_eq(error.path, "$.fields[0].candidates[0].authority")
      assert_eq(error.message, "expected integer number")
    }
  }
}

///|
test "missing candidate field reports exact required path" {
  let text =
    #|{"schema_version":"sourcefuse.record.v1","fields":[{"name":"name","candidates":[{"value":"A","source_id":"x","source_kind":"human","authority":1,"revision":3,"state":"proposed"}]}]}
  match parse_record_document(text) {
    Ok(_) => fail("expected missing field")
    Err(error) => {
      assert_eq(error.kind, MissingField)
      assert_eq(error.path, "$.fields[0].candidates[0].confidence")
    }
  }
}

///|
test "end to end adapter parses reconciles and emits report v1" {
  let text =
    #|{"schema_version":"sourcefuse.record.v1","default_policy":{"normalization":"ascii_trim_case_fold"},"fields":[{"name":"name","candidates":[{"value":" Alice ","source_id":"human","source_kind":"human","authority":100,"confidence":90,"revision":1,"state":"proposed"},{"value":"alice","source_id":"model","source_kind":"model","authority":100,"confidence":90,"revision":1,"state":"proposed"}]},{"name":"phone","candidates":[{"value":"138","source_id":"left","source_kind":"rule","authority":50,"confidence":90,"revision":1,"state":"proposed"},{"value":"139","source_id":"right","source_kind":"rule","authority":50,"confidence":90,"revision":1,"state":"proposed"}]}]}
  let output = match reconcile_record_json(text, pretty=false) {
    Err(error) => fail(error.message)
    Ok(value) => value
  }
  let root = @json.parse(output)
  guard root is Object(object) else {
    fail("expected report object")
  }
  assert_eq(
    object.get("schema_version"),
    Some(Json::string("sourcefuse.decision-report.v1")),
  )
  assert_eq(object.get("status"), Some(Json::string("reconciled")))
  guard object.get("summary") is Some(Object(summary)) else {
    fail("expected summary")
  }
  assert_eq(summary.get("declared_fields"), Some(Json::number(2.0)))
  assert_eq(summary.get("resolved_fields"), Some(Json::number(1.0)))
  assert_eq(summary.get("conflicted_fields"), Some(Json::number(1.0)))

  guard object.get("fields") is Some(Array(fields)) else {
    fail("expected fields")
  }
  assert_eq(fields.length(), 2)
  guard fields[0] is Object(name_field) else {
    fail("expected first field object")
  }
  assert_eq(name_field.get("name"), Some(Json::string("name")))
  assert_eq(name_field.get("value"), Some(Json::string("alice")))
  assert_eq(name_field.get("supporter_count"), Some(Json::number(2.0)))
  guard name_field.get("considered") is Some(Array(considered)) else {
    fail("expected considered provenance")
  }
  assert_eq(considered.length(), 2)
  guard considered[0] is Object(first_considered) else {
    fail("expected considered candidate object")
  }
  assert_eq(first_considered.get("source_id"), Some(Json::string("human")))
  assert_eq(first_considered.get("source_kind"), Some(Json::string("human")))
  assert_eq(first_considered.get("state"), Some(Json::string("proposed")))
  guard name_field.get("supporters") is Some(Array(supporters)) else {
    fail("expected supporter provenance")
  }
  assert_eq(supporters.length(), 2)
}

///|
test "decision report serialization is deterministic for identical data" {
  let input = @core.record([
    @core.field("name", [
      @core.candidate("A", "human", @core.Human, 10, 90, 1, @core.Proposed),
    ]),
  ])
  let report = @core.decision_report(@core.reconcile_record(input))
  let first = decision_report_json(report, pretty=false)
  let second = decision_report_json(report, pretty=false)
  assert_eq(first, second)
}

///|
test "invalid record report serializes issues without field decisions" {
  let result = @core.reconcile_record(
    @core.record([
      @core.field("name", []),
      @core.field("name", []),
    ]),
  )
  let output = decision_report_json(@core.decision_report(result), pretty=false)
  let root = @json.parse(output)
  guard root is Object(object) else {
    fail("expected report object")
  }
  assert_eq(object.get("status"), Some(Json::string("invalid")))
  guard object.get("issues") is Some(Array(issues)) else {
    fail("expected issues")
  }
  assert_eq(issues.length(), 1)
  guard issues[0] is Object(issue) else {
    fail("expected issue object")
  }
  assert_eq(issue.get("kind"), Some(Json::string("duplicate_field_name")))
  assert_eq(issue.get("field_name"), Some(Json::string("name")))
}
