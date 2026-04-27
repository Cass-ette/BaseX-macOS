# BaseX-macOS

Unofficial macOS app packaging for [BaseX](https://basex.org/).

This repository builds a self-contained `BaseX.app` and optional `.dmg` for macOS by:

- downloading the official upstream BaseX ZIP release
- bundling a minimal Java runtime
- generating a native `.app` bundle with Finder-friendly launch behavior

## Why this exists

BaseX ships a GUI on macOS, but the official distribution does not currently provide a native macOS `.app` installer. This repository fills that packaging gap.

## What you get

- `BaseX.app`
- optional `BaseX-<version>.dmg`
- no Homebrew dependency at runtime

## Current limitations

- the app currently uses the default macOS application icon
- artifacts are not code signed or notarized
- the package is unofficial and should be labeled accordingly in releases

## Requirements

- macOS
- JDK 17 or newer
- `curl`
- `unzip`
- `hdiutil`

## Build locally

Build the default upstream version:

```bash
./scripts/build.sh
```

Build a specific upstream version:

```bash
BASEX_VERSION=12.2 ./scripts/build.sh
```

Outputs are written to:

- `dist/BaseX.app`

Build a DMG as well:

```bash
CREATE_DMG=1 ./scripts/build.sh
```

Additional output:

- `dist/BaseX-<version>.dmg`

## Release strategy

This repository does not modify BaseX itself. It only repackages the official upstream release for macOS convenience.

Recommended maintenance flow:

1. update `BASEX_VERSION` in the workflow or pass it at dispatch time
2. run the GitHub Actions build on `macos-latest`
3. upload `BaseX.app` and `.dmg` to a GitHub Release

## License

The packaging code in this repository is released under the MIT License.

BaseX itself is an upstream project with its own license. See [NOTICE.md](NOTICE.md).
