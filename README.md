# BaseX-macOS

Unofficial macOS app packaging for [BaseX](https://basex.org/).

This repository builds a self-contained `BaseX.app` and optional `.dmg` for macOS by:

- downloading the official upstream BaseX ZIP release
- bundling a full JDK runtime for compatibility
- generating a native `.app` bundle with Finder-friendly launch behavior

## Why this exists

BaseX ships a GUI on macOS, but the official distribution does not currently provide a native macOS `.app` installer. This repository fills that packaging gap.

## What you get

- `BaseX.app`
- optional `BaseX-<version>.dmg`
- no Homebrew dependency at runtime

## Current limitations

- notarization depends on Apple Developer credentials being configured as GitHub secrets
- the package is unofficial and should be labeled accordingly in releases

## Requirements

- macOS
- JDK 17 or newer
- `curl`
- `unzip`
- `hdiutil`

The repository already includes a committed `BaseX.icns`, so normal builds do not need icon tooling.

## Build locally

Build the default upstream version:

```bash
./scripts/build.sh
```

The default upstream version is stored in [`.basex-version`](.basex-version).

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

Build a signed app locally if you have a valid signing identity in Keychain:

```bash
SIGN_APP=1 APPLE_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build.sh
```

## Release strategy

This repository does not modify BaseX itself. It only repackages the official upstream release for macOS convenience.

Recommended maintenance flow:

1. update [`.basex-version`](.basex-version) when upstream BaseX changes
2. run the `Release BaseX macOS App` workflow
3. optionally override the upstream version or release tag at dispatch time
4. let the workflow publish `BaseX.app`, `.dmg`, and SHA256 files as a GitHub Release

## Optional signing and notarization

The release workflow can sign and notarize artifacts when these repository secrets are configured:

- `APPLE_CERTIFICATE_P12_BASE64`: Base64-encoded Developer ID Application certificate in `.p12` form
- `APPLE_CERTIFICATE_PASSWORD`: Password for the `.p12` file
- `APPLE_SIGNING_IDENTITY`: Exact `codesign` identity name
- `APPLE_ID`: Apple account email used for notarization
- `APPLE_APP_SPECIFIC_PASSWORD`: App-specific password for notarization
- `APPLE_TEAM_ID`: Apple Developer team ID

If only the signing secrets are present, the workflow will produce signed artifacts.
If both signing and notarization secrets are present, the workflow will notarize and staple the app and DMG.

## Release outputs

- `BaseX-<version>.app.zip`
- `BaseX-<version>.dmg`
- `BaseX-<version>.app.zip.sha256`
- `BaseX-<version>.dmg.sha256`

## License

The packaging code in this repository is released under the MIT License.

BaseX itself is an upstream project with its own license. See [NOTICE.md](NOTICE.md).
