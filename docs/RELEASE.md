# Release process

SourceFuse releases are cut from a green `main` commit.

## Release candidate checks

Run:

```bash
moon update
moon check --target all --deny-warn
moon test --target all
moon build --target all
moon info --target native
moon package --list
moon run cmd/sourcefuse examples/human-ocr-model/record.json
moon run cmd/sourcefuse examples/device-human-model/record.json
moon run cmd/sourcefuse examples/conflicted-record/record.json
```

CI performs the same contract checks in a platform-aware form.

Before tagging:

1. `moon.mod` version matches the intended tag without the `v` prefix;
2. `CHANGELOG.md` contains that version;
3. the public API contract in `docs/API.md` still matches generated
   `.mbti` interfaces;
4. wire schema identifiers are unchanged unless a schema migration was
   intentional;
5. Ubuntu native, Windows native, and portable-target CI are green;
6. `moon package --list` contains the expected source/docs/examples and no
   local generated output.

## Tagging

Release tags use:

```text
vMAJOR.MINOR.PATCH
```

The first release is `v0.1.0`.

The GitHub release should summarize library behavior and compatibility boundaries
rather than presenting the CLI as the project itself.
