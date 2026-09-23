# Reference CLI

`cmd/sourcefuse` is a deliberately thin native adapter around the stable wire
API. It exists to make the library easy to evaluate and script; it is not a
separate workflow engine or product layer.

## Usage

```text
sourcefuse <record.json>
```

From the repository:

```bash
moon run cmd/sourcefuse examples/human-ocr-model/record.json
```

Help:

```bash
moon run cmd/sourcefuse --help
```

## Contract

Input:

- UTF-8 JSON file
- schema: `sourcefuse.record.v1`

Output on successful parsing/reconciliation:

- JSON on stdout
- schema: `sourcefuse.decision-report.v1`
- exit code `0`

A report may contain field conflicts and still exit `0`: conflict is a
domain result produced by SourceFuse, not a CLI failure.

Errors:

- wire/schema/validation error → diagnostic on stderr, exit code `1`
- invalid CLI usage or unreadable input file → diagnostic on stderr, exit code `2`

## Architectural boundary

The executable imports `wire/` plus native file/process helpers. Neither
`core/` nor `wire/` imports the CLI. The package is marked native-only, so
portable-target CI continues to test the reusable library independently.
