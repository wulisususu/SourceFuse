///|
/// Stable input schema identifier.
pub const RECORD_SCHEMA : String = "sourcefuse.record.v1"

///|
fn parse_json(text : String) -> Result[Json, WireError] {
  try {
    Ok(@json.parse(text))
  } catch {
    (_ : @json.ParseError) =>
      Err(wire_error(InvalidJson, "$", "document is not valid JSON"))
  }
}

///|
fn required_string(
  object : Map[String, Json],
  key : String,
  path : String,
) -> Result[String, WireError] {
  match object.get(key) {
    Some(String(value)) => Ok(value)
    Some(_) =>
      Err(wire_error(InvalidType, "{path}.{key}", "expected string"))
    None =>
      Err(wire_error(MissingField, "{path}.{key}", "required field is missing"))
  }
}

///|
fn required_bool(
  object : Map[String, Json],
  key : String,
  path : String,
) -> Result[Bool, WireError] {
  match object.get(key) {
    Some(True) => Ok(true)
    Some(False) => Ok(false)
    Some(_) =>
      Err(wire_error(InvalidType, "{path}.{key}", "expected boolean"))
    None =>
      Err(wire_error(MissingField, "{path}.{key}", "required field is missing"))
  }
}

///|
fn required_int(
  object : Map[String, Json],
  key : String,
  path : String,
) -> Result[Int, WireError] {
  match object.get(key) {
    Some(Number(value, ..)) => {
      let integer = value.to_int()
      if integer.to_double() == value {
        Ok(integer)
      } else {
        Err(wire_error(InvalidValue, "{path}.{key}", "expected integer number"))
      }
    }
    Some(_) =>
      Err(wire_error(InvalidType, "{path}.{key}", "expected integer number"))
    None =>
      Err(wire_error(MissingField, "{path}.{key}", "required field is missing"))
  }
}

///|
fn parse_source_kind(value : String, path : String) -> Result[@core.SourceKind, WireError] {
  match value {
    "human" => Ok(@core.Human)
    "device" => Ok(@core.Device)
    "rule" => Ok(@core.Rule)
    "model" => Ok(@core.Model)
    "external" => Ok(@core.External)
    _ =>
      Err(
        wire_error(
          InvalidValue,
          path,
          "expected human, device, rule, model, or external",
        ),
      )
  }
}

///|
fn parse_state(value : String, path : String) -> Result[@core.CandidateState, WireError] {
  match value {
    "proposed" => Ok(@core.Proposed)
    "confirmed" => Ok(@core.Confirmed)
    "locked" => Ok(@core.Locked)
    _ =>
      Err(
        wire_error(
          InvalidValue,
          path,
          "expected proposed, confirmed, or locked",
        ),
      )
  }
}

///|
fn parse_normalization(
  value : String,
  path : String,
) -> Result[@core.NormalizationMode, WireError] {
  match value {
    "exact" => Ok(@core.Exact)
    "ascii_trim" => Ok(@core.AsciiTrim)
    "ascii_trim_case_fold" => Ok(@core.AsciiTrimCaseFold)
    _ =>
      Err(
        wire_error(
          InvalidValue,
          path,
          "expected exact, ascii_trim, or ascii_trim_case_fold",
        ),
      )
  }
}

///|
fn parse_rank_dimension(
  value : String,
  path : String,
) -> Result[@core.RankDimension, WireError] {
  match value {
    "authority" => Ok(@core.AuthorityRank)
    "confidence" => Ok(@core.ConfidenceRank)
    "revision" => Ok(@core.RevisionRank)
    _ =>
      Err(
        wire_error(
          InvalidValue,
          path,
          "expected authority, confidence, or revision",
        ),
      )
  }
}

///|
fn parse_candidate(value : Json, path : String) -> Result[@core.Candidate, WireError] {
  guard value is Object(object) else {
    return Err(wire_error(InvalidType, path, "candidate must be an object"))
  }
  let candidate_value = match required_string(object, "value", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let source_id = match required_string(object, "source_id", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let source_kind_text = match required_string(object, "source_kind", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let source_kind = match parse_source_kind(source_kind_text, "{path}.source_kind") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let authority = match required_int(object, "authority", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let confidence = match required_int(object, "confidence", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let revision = match required_int(object, "revision", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let state_text = match required_string(object, "state", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let state = match parse_state(state_text, "{path}.state") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(
    @core.candidate(
      candidate_value,
      source_id,
      source_kind,
      authority,
      confidence,
      revision,
      state,
    ),
  )
}

///|
fn parse_source_authorities(
  object : Map[String, Json],
  path : String,
) -> Result[Array[@core.SourceAuthority], WireError] {
  let out : Array[@core.SourceAuthority] = []
  match object.get("source_authorities") {
    None | Some(Null) => Ok(out)
    Some(Array(items)) => {
      for index, item in items {
        let item_path = "{path}.source_authorities[{index}]"
        guard item is Object(fields) else {
          return Err(wire_error(InvalidType, item_path, "entry must be an object"))
        }
        let kind_text = match required_string(fields, "source_kind", item_path) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let kind = match parse_source_kind(kind_text, "{item_path}.source_kind") {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let authority = match required_int(fields, "authority", item_path) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        out.push(@core.source_authority(kind, authority))
      }
      Ok(out)
    }
    Some(_) =>
      Err(
        wire_error(
          InvalidType,
          "{path}.source_authorities",
          "expected array",
        ),
      )
  }
}

///|
fn parse_rank_order(
  object : Map[String, Json],
  path : String,
) -> Result[Array[@core.RankDimension], WireError] {
  let out : Array[@core.RankDimension] = []
  match object.get("rank_order") {
    None | Some(Null) =>
      Ok([@core.AuthorityRank, @core.ConfidenceRank, @core.RevisionRank])
    Some(Array(items)) => {
      for index, item in items {
        guard item is String(text) else {
          return Err(
            wire_error(
              InvalidType,
              "{path}.rank_order[{index}]",
              "expected string",
            ),
          )
        }
        match parse_rank_dimension(text, "{path}.rank_order[{index}]") {
          Ok(value) => out.push(value)
          Err(error) => return Err(error)
        }
      }
      Ok(out)
    }
    Some(_) =>
      Err(wire_error(InvalidType, "{path}.rank_order", "expected array"))
  }
}

///|
fn parse_policy_json(
  value : Json,
  path : String,
) -> Result[@core.ReconcilePolicy, WireError] {
  guard value is Object(object) else {
    return Err(wire_error(InvalidType, path, "policy must be an object"))
  }

  let normalization = match object.get("normalization") {
    None | Some(Null) => @core.Exact
    Some(String(text)) =>
      match parse_normalization(text, "{path}.normalization") {
        Ok(value) => value
        Err(error) => return Err(error)
      }
    Some(_) =>
      return Err(
        wire_error(InvalidType, "{path}.normalization", "expected string"),
      )
  }

  let confirmed_dominates = match object.get("confirmed_dominates") {
    None | Some(Null) => true
    Some(True) => true
    Some(False) => false
    Some(_) =>
      return Err(
        wire_error(
          InvalidType,
          "{path}.confirmed_dominates",
          "expected boolean",
        ),
      )
  }

  let rank_order = match parse_rank_order(object, path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let source_authorities = match parse_source_authorities(object, path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(
    @core.policy(
      normalization,
      confirmed_dominates,
      rank_order,
      source_authorities,
    ),
  )
}

///|
fn parse_candidates(
  object : Map[String, Json],
  path : String,
) -> Result[Array[@core.Candidate], WireError] {
  guard object.get("candidates") is Some(Array(items)) else {
    return match object.get("candidates") {
      None =>
        Err(
          wire_error(
            MissingField,
            "{path}.candidates",
            "required field is missing",
          ),
        )
      _ =>
        Err(wire_error(InvalidType, "{path}.candidates", "expected array"))
    }
  }
  let out : Array[@core.Candidate] = []
  for index, item in items {
    match parse_candidate(item, "{path}.candidates[{index}]") {
      Ok(candidate) => out.push(candidate)
      Err(error) => return Err(error)
    }
  }
  Ok(out)
}

///|
fn parse_field(value : Json, path : String) -> Result[@core.FieldInput, WireError] {
  guard value is Object(object) else {
    return Err(wire_error(InvalidType, path, "field must be an object"))
  }
  let name = match required_string(object, "name", path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let candidates = match parse_candidates(object, path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match object.get("policy") {
    None | Some(Null) => Ok(@core.field(name, candidates))
    Some(value) =>
      match parse_policy_json(value, "{path}.policy") {
        Ok(policy) => Ok(@core.field_with_policy(name, candidates, policy))
        Err(error) => Err(error)
      }
  }
}

///|
/// Parse a versioned SourceFuse record document.
pub fn parse_record_document(text : String) -> Result[@core.RecordInput, WireError] {
  let root = match parse_json(text) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  guard root is Object(object) else {
    return Err(wire_error(InvalidType, "$", "record document must be an object"))
  }

  let schema = match required_string(object, "schema_version", "$") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if schema != RECORD_SCHEMA {
    return Err(
      wire_error(
        UnsupportedSchema,
        "$.schema_version",
        "unsupported schema version: {schema}",
      ),
    )
  }

  let default = match object.get("default_policy") {
    None | Some(Null) => @core.default_policy()
    Some(value) =>
      match parse_policy_json(value, "$.default_policy") {
        Ok(policy) => policy
        Err(error) => return Err(error)
      }
  }

  guard object.get("fields") is Some(Array(items)) else {
    return match object.get("fields") {
      None =>
        Err(wire_error(MissingField, "$.fields", "required field is missing"))
      _ => Err(wire_error(InvalidType, "$.fields", "expected array"))
    }
  }

  let fields : Array[@core.FieldInput] = []
  for index, item in items {
    match parse_field(item, "$.fields[{index}]") {
      Ok(field) => fields.push(field)
      Err(error) => return Err(error)
    }
  }
  Ok(@core.record_with_policy(fields, default))
}
