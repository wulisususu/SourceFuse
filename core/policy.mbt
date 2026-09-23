///|
/// Built-in deterministic normalization modes.
///
/// AsciiTrimCaseFold intentionally performs ASCII-only case folding.
/// Non-ASCII text is preserved except for surrounding whitespace.
pub(all) enum NormalizationMode {
  Exact
  AsciiTrim
  AsciiTrimCaseFold
} derive(Eq, @debug.Debug)

pub extend NormalizationMode with Eq::{not_equal, equal}
pub extend NormalizationMode with @debug.Debug::{to_repr}

///|
/// Candidate dimensions that can participate in policy ranking.
pub(all) enum RankDimension {
  AuthorityRank
  ConfidenceRank
  RevisionRank
} derive(Eq, @debug.Debug)

pub extend RankDimension with Eq::{not_equal, equal}
pub extend RankDimension with @debug.Debug::{to_repr}

///|
/// Override candidate authority for one broad source kind.
///
/// This lets an application express policies such as Human > Device > Model
/// without rewriting the reconciliation engine.
pub(all) struct SourceAuthority {
  source_kind : SourceKind
  authority : Int
} derive(Eq, @debug.Debug)

pub extend SourceAuthority with Eq::{not_equal, equal}
pub extend SourceAuthority with @debug.Debug::{to_repr}

///|
/// Configurable deterministic reconciliation policy.
///
/// Locked semantics are deliberately absent: a locked candidate always remains
/// a non-configurable safety invariant.
pub(all) struct ReconcilePolicy {
  normalization : NormalizationMode
  confirmed_dominates : Bool
  rank_order : Array[RankDimension]
  source_authorities : Array[SourceAuthority]
} derive(Eq, @debug.Debug)

pub extend ReconcilePolicy with Eq::{not_equal, equal}
pub extend ReconcilePolicy with @debug.Debug::{to_repr}

///|
/// Stable default reconciliation policy.
pub fn default_policy() -> ReconcilePolicy {
  {
    normalization: Exact,
    confirmed_dominates: true,
    rank_order: [AuthorityRank, ConfidenceRank, RevisionRank],
    source_authorities: [],
  }
}

///|
/// Construct an explicit policy.
///
/// Omitting a rank dimension intentionally disables that tie-break step.
/// Repeating a dimension is harmless but unnecessary.
pub fn policy(
  normalization : NormalizationMode,
  confirmed_dominates : Bool,
  rank_order : Array[RankDimension],
  source_authorities : Array[SourceAuthority],
) -> ReconcilePolicy {
  {
    normalization,
    confirmed_dominates,
    rank_order,
    source_authorities,
  }
}

///|
/// Convenience constructor for one source-kind authority override.
pub fn source_authority(
  source_kind : SourceKind,
  authority : Int,
) -> SourceAuthority {
  { source_kind, authority }
}

///|
/// Convert a value to the policy's canonical comparison form.
pub fn normalize_value(
  value : String,
  mode : NormalizationMode,
) -> String {
  match mode {
    Exact => value
    AsciiTrim => value.trim().to_owned()
    AsciiTrimCaseFold => value.trim().to_owned().to_lower()
  }
}
