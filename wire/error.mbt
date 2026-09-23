///|
/// Stable categories for JSON wire errors.
pub(all) enum WireErrorKind {
  InvalidJson
  UnsupportedSchema
  MissingField
  InvalidType
  InvalidValue
} derive(Eq, @debug.Debug)

pub extend WireErrorKind with Eq::{not_equal, equal}
pub extend WireErrorKind with @debug.Debug::{to_repr}

///|
/// Structured parse error with a JSON-like path.
pub(all) struct WireError {
  kind : WireErrorKind
  path : String
  message : String
} derive(Eq, @debug.Debug)

pub extend WireError with Eq::{not_equal, equal}
pub extend WireError with @debug.Debug::{to_repr}

///|
fn wire_error(
  kind : WireErrorKind,
  path : String,
  message : String,
) -> WireError {
  { kind, path, message }
}
