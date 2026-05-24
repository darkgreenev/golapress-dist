# goLaPress Dist Release Workflow

This document defines how `golapress-dist` should be updated from this private repository and when that update also requires a new public release.

Use this as the source of truth for packaging and distribution work. Do not rely on inference from shell scripts alone.

## Repositories

There are two repositories in this workflow:

- `golapress`: the private source repository where the application and packaging logic are developed
- `golapress-dist`: the public distribution repository used by general installers and released binaries

Public installers and update flows consume assets from `golapress-dist`.

## Local Checkout Layout

For distribution work on a single machine, keep the two repositories in sibling folders.

Example:

```text
/home/ubuntu/localworktemp/golapress
/home/ubuntu/localworktemp/golapress-dist
```

With that layout, run the sync command from the private repo like this:

```bash
./scripts/sync-dist-repo-files.sh ../golapress-dist
```

This keeps the private source repo and the public distribution repo separate while making sync commands simple and predictable.

## Local Binary Output Convention

When building binaries from the private `golapress` checkout, use these locations consistently:

- local runnable contributor build: `dist/local/golapress`
- public release payloads: `dist/release/`

Do not leave ad hoc binaries in the repository root such as:

```text
./golapress
```

That makes it unclear which binary is current and which one was used for release work.

Recommended commands:

For a local manual binary build:

```bash
mkdir -p dist/local
go build -trimpath -o dist/local/golapress ./cmd/golapress
```

For public release artifacts:

```bash
./scripts/build-dist.sh vX.Y.Z
```

That writes the release archives and metadata under:

```text
dist/release/
```

Current release workflow assumes:

- archives are built in `golapress/dist/release/`
- `latest.json` is published from `golapress-dist` as the bootstrap metadata file
- release assets are uploaded from `golapress/dist/release/` into a `golapress-dist` GitHub release
- GitHub release uploads use the archives directly from `golapress/dist/release/`

## What Lives In golapress-dist

`golapress-dist` is expected to carry two kinds of public distribution material:

- bootstrap metadata, mirrored public support files, and docs
- released binary artifacts

Bootstrap metadata, mirrored public support files, and docs include things like:

- `.env.example`
- public `README.md`
- `Dockerfile.standard`
- `Dockerfile.withData`
- mirrored installer scripts such as `run-standard.sh`, `run-with-data.sh`, and `install-vps.sh`
- public install docs needed by the distribution repo
- `latest.json`

Binary artifacts include:

- `golapress-linux-amd64.tar.gz`
- `golapress-linux-arm64.tar.gz`
- `golapress-windows-amd64.zip`
- `install-vps.sh`
- `run-standard.sh`
- `run-with-data.sh`
- `checksums.txt`

Each platform archive is now self-contained. It includes the binary plus the public release support files needed for direct binary and Docker-based installs.

## Two Update Types

There are two distinct update operations. They are related, but they are not the same thing.

### 1. Dist Repo Sync

This updates the file-based content in `golapress-dist`.

Examples:

- README changes
- documentation-only changes
- bootstrap metadata publication changes

This is handled from the private repo with:

```bash
./scripts/sync-dist-repo-files.sh /path/to/golapress-dist
```

At the time of writing, that sync script copies:

- `.env.example`
- `Dockerfile.withData`
- `Dockerfile.standard`
- `Makefile.dist` to `golapress-dist/Makefile`
- `README.md`
- `scripts/with-data-entrypoint.sh`
- `scripts/standard-entrypoint.sh`
- `scripts/install-vps.sh`
- `run-with-data.sh`
- `run-standard.sh`
- `docs/vps_binary_install.md`

After syncing, commit and push the resulting changes in the `golapress-dist` checkout.

### 2. Public Binary Release

This publishes new binary assets and refreshes `latest.json` so installers and updaters pull the new version.

This is built from the private repo with:

```bash
./scripts/build-dist.sh <version>
```

That script writes release artifacts under:

```text
dist/release/
```

It produces:

- platform archives
- version-matched installer script assets
- `checksums.txt`
- `latest.json`

The script does not write to the repository root. Release artifacts are expected to stay under `dist/release/`.

The generated `latest.json` points to GitHub release asset URLs in `golapress-dist`, including the installer script assets, using the supplied version string.

## When A Dist Repo Commit Is Enough

A `golapress-dist` commit without a new release is enough when the public change is only in distribution files and does not require a new application binary.

Examples:

- README clarifications
- installer or Docker doc changes that should be visible in the dist repo
- bootstrap metadata publication changes
- mirrored public support file updates when you are not yet cutting a fresh release

In these cases:

1. sync files into `golapress-dist`
2. commit and push `golapress-dist`
3. do not cut a new binary release unless the binary itself must change

## When A New Release Is Required

A new `golapress-dist` release is required when public users need updated application binaries.

Examples:

- backend or frontend application changes in `golapress`
- new app behavior required by released installers or packaged Docker files
- bug fixes in the binary itself
- any change where `Tools > Updates` should deliver a newer build

In these cases:

1. ensure the desired source changes are committed in `golapress`
2. run `./scripts/build-dist.sh <version>` in `golapress`
3. publish the generated archives, installer scripts, and `checksums.txt` as a GitHub release in `golapress-dist`
4. update `latest.json` in `golapress-dist` to match that release
5. commit and push the `latest.json` update in `golapress-dist`

## Current Practical Rule

Use this rule when deciding whether to release:

- if only `golapress-dist` docs or bootstrap metadata handling changed, a dist commit is usually enough
- if the `golapress` binary behavior changed, or the shipped release support files changed, cut a new `golapress-dist` release
- plugin targets in `cut-release` auto-bump the patch version when the source manifest still matches the last published version; if a developer has already manually bumped a plugin version, that manual version wins

## Why latest.json Matters

The released binary and installer asset paths are not guessed dynamically. Installers read `latest.json` and follow its URLs.

This matters for:

- the Docker entrypoint installers
- the VPS binary installer
- binary update flows in the admin UI

If `latest.json` still points at old assets, users will keep installing or updating to the old release even if the dist repo has newer docs.

## Standard Workflow

For a packaging-only update:

1. make the packaging or doc changes in `golapress`
2. run:

```bash
./scripts/sync-dist-repo-files.sh /path/to/golapress-dist
```

3. review the `golapress-dist` diff
4. commit and push `golapress-dist`

For an application release:

1. finish and commit the app changes in `golapress`
2. sync any needed dist repo files into `golapress-dist`
3. build artifacts:

```bash
./scripts/build-dist.sh vX.Y.Z
```

4. publish a `golapress-dist` GitHub release using the generated archives, installer scripts, and `checksums.txt` from `dist/release/`
5. update `latest.json` in the sibling `golapress-dist/` checkout to point at that release version
6. commit and push any tracked dist repo file updates, including `latest.json`

## VPS Installer Specific Rule

Changes to these public distribution files:

- `scripts/install-vps.sh`
- `docs/vps_binary_install.md`

must be included in a new public release if you want public VPS users to get the version-matched installer asset immediately.

Those changes do not always require a new application binary rebuild, but they do require refreshed release assets when you want the public installer surface to change.

They still require a `golapress-dist` docs sync so the bootstrap repo stays current.

## Docker Installer Specific Rule

Changes to these files:

- `Dockerfile.standard`
- `Dockerfile.withData`
- `scripts/standard-entrypoint.sh`
- `scripts/with-data-entrypoint.sh`
- `run-standard.sh`
- `run-with-data.sh`

must be shipped in a new public release because the platform archives now carry the Docker support files.

Syncing the docs/bootstrap repo is still useful, but it is not sufficient on its own for release consumers.

## Admin Updater Relationship

Released binary installs expose `Tools > Updates` in the admin UI.
Source-checkout development runs keep the page for diagnostics, but the update and rollback actions are disabled there so the source tree is not mistaken for an installed release binary.

That updater checks `APP_UPDATE_LATEST_URL`, downloads the archive referenced by `latest.json`, verifies it against `checksums.txt`, and replaces the current binary.

That means the release process is not only for first-time installs. It also drives in-place binary updates for existing installs.

Source-checkout development runs do not use this updater flow. In development/source builds, the Updates screen may still show binary diagnostics, but install and rollback actions are disabled because a repo/dev executable should be rebuilt or restarted from source instead of self-updated from release archives.

## Operational Notes

- `sync-dist-repo-files.sh` updates only the files it explicitly copies. If a new public installer or doc should ship in `golapress-dist`, add it to that script.
- `build-dist.sh` does not publish GitHub releases by itself. It prepares the release payload locally under `dist/release/`.
- `latest.json` and the GitHub release assets must stay in sync.
- Version strings passed to `build-dist.sh` become part of the generated release URLs.

## Recommended Next Improvement

The repo should eventually add a documented or scripted release command that performs:

1. dist file sync
2. artifact build
3. release asset upload
4. `latest.json` publish/update

Right now the workflow is defined, but it is not yet fully automated end to end.
