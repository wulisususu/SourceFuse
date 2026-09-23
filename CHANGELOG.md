# Changelog

All notable changes to SourceFuse are documented here.

The project follows semantic versioning. Wire schema identifiers are versioned
independently and are treated as compatibility contracts.

## [0.1.1] - 2026-09-23

Submission-review hardening release.

### Changed

- rewrote the repository front page around the reusable library contract rather
  than internal implementation milestones;
- added a reviewer-first evaluation path and explicit design-differentiation
  document;
- clarified that supporters match the resolved canonical value after
  normalization;
- removed internal gate terminology from public core API comments.

### Compatibility

- no reconciliation behavior or wire schema changed;
- `sourcefuse.record.v1` and `sourcefuse.decision-report.v1` remain unchanged.

## [0.1.0] - 2026-09-23

Initial public release.

### Added

- deterministic single-field reconciliation with explicit conflict results;
- locked and confirmed candidate semantics;
- configurable authority, confidence, and revision ranking;
- exact, ASCII trim, and ASCII trim + case-fold normalization modes;
- per-`SourceKind` authority overrides;
- structured multi-field record reconciliation with failure isolation;
- machine-readable decision traces and provenance-preserving reports;
- stable `sourcefuse.record.v1` input and `sourcefuse.decision-report.v1`
  output JSON schemas;
- native reference CLI for evaluating JSON records;
- runnable human/OCR/model, device/human/model, and partial-conflict examples;
- Ubuntu + Windows native CI and portable `wasm`, `wasm-gc`, `js`, and
  `native` checks/tests/builds.

### Compatibility notes

- v0.1 reconciles textual `String` values;
- `supporter_count` is explanatory evidence and is not a voting rule;
- exact ties between different values remain unresolved instead of depending
  on input order;
- the CLI is a reference adapter and is not part of the core arbitration API.
