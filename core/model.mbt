///|
/// Logical origin of a candidate value.
pub(all) enum SourceKind {
  Human
  Device
  Rule
  Model
  External
} derive(Eq, @debug.Debug)

pub extend SourceKind with Eq::{not_equal, equal}
pub extend SourceKind with @debug.Debug::{to_repr}

///|
/// Lifecycle state of a candidate.
///
/// Proposed is ordinary evidence.
/// Confirmed is an explicit confirmation.
/// Locked means the value must not be silently replaced.
pub(all) enum CandidateState {
  Proposed
  Confirmed
  Locked
} derive(Eq, @debug.Debug)

pub extend CandidateState with Eq::{not_equal, equal}
pub extend CandidateState with @debug.Debug::{to_repr}

///|
/// A value proposed by one source.
///
/// authority, confidence, and revision are caller-provided deterministic
/// integers. SourceFuse deliberately does not read wall-clock time.
pub(all) struct Candidate {
  value : String
  source_id : String
  source_kind : SourceKind
  authority : Int
  confidence : Int
  revision : Int
  state : CandidateState
} derive(Eq, @debug.Debug)

pub extend Candidate with Eq::{not_equal, equal}
pub extend Candidate with @debug.Debug::{to_repr}

///|
/// Construct a candidate value.
pub fn candidate(
  value : String,
  source_id : String,
  source_kind : SourceKind,
  authority : Int,
  confidence : Int,
  revision : Int,
  state : CandidateState,
) -> Candidate {
  {
    value,
    source_id,
    source_kind,
    authority,
    confidence,
    revision,
    state,
  }
}

///|
/// Why reconciliation could not return one deterministic value.
pub(all) enum ConflictKind {
  EmptyInput
  LockedConflict
  EqualPriorityConflict
} derive(Eq, @debug.Debug)

pub extend ConflictKind with Eq::{not_equal, equal}
pub extend ConflictKind with @debug.Debug::{to_repr}

///|
/// Final reconciliation state.
pub(all) enum ReconcileStatus {
  Resolved
  Conflict
} derive(Eq, @debug.Debug)

pub extend ReconcileStatus with Eq::{not_equal, equal}
pub extend ReconcileStatus with @debug.Debug::{to_repr}

///|
/// Machine-readable rule identifiers used in the decision trace.
pub(all) enum DecisionRule {
  EmptyCandidates
  LockedValue
  LockedValuesConflict
  ConfirmedDominates
  ValuesNormalized
  SourceAuthorityOverrideApplied
  HigherAuthority
  HigherConfidence
  NewerRevision
  EqualPriorityValuesConflict
  ResolvedValue
} derive(Eq, @debug.Debug)

pub extend DecisionRule with Eq::{not_equal, equal}
pub extend DecisionRule with @debug.Debug::{to_repr}

///|
/// One explanation step emitted by the reconciliation engine.
pub(all) struct DecisionStep {
  rule : DecisionRule
  detail : String
} derive(Eq, @debug.Debug)

pub extend DecisionStep with Eq::{not_equal, equal}
pub extend DecisionStep with @debug.Debug::{to_repr}

///|
/// Output of reconciliation.
///
/// considered preserves all caller evidence.
/// supporters contains every original candidate whose exact value equals the
/// resolved value, including lower-ranked corroborating evidence.
pub(all) struct ReconcileResult {
  status : ReconcileStatus
  value : String?
  conflict : ConflictKind?
  considered : Array[Candidate]
  supporters : Array[Candidate]
  trace : Array[DecisionStep]
} derive(Eq, @debug.Debug)

pub extend ReconcileResult with Eq::{not_equal, equal}
pub extend ReconcileResult with @debug.Debug::{to_repr}
