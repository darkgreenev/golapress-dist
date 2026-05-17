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
- `latest.json` and `checksums.txt` are copied from `golapress/dist/release/` into the sibling `golapress-dist/` checkout
- GitHub release uploads use the archives directly from `golapress/dist/release/`

## What Lives In golapress-dist

`golapress-dist` is expected to carry two kinds of public distribution material:

- file-based packaging and installer content
- released binary artifacts

File-based packaging content includes things like:

- `.env.example`
- public `README.md`
- `Dockerfile.standard`
- `Dockerfile.withData`
- release installer scripts such as `run-standard.sh`, `run-with-data.sh`, and `install-vps.sh`
- public install docs needed by the distribution repo

Binary artifacts include:

- `golapress-linux-amd64.tar.gz`
- `golapress-linux-arm64.tar.gz`
- `golapress-windows-amd64.zip`
- `checksums.txt`
- `latest.json`

## Two Update Types

There are two distinct update operations. They are related, but they are not the same thing.

### 1. Dist Repo Sync

This updates the file-based content in `golapress-dist`.

Examples:

- README changes
- Docker packaging changes
- new public installer scripts
- installer documentation changes

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
- `checksums.txt`
- `latest.json`

The script does not write to the repository root. Release artifacts are expected to stay under `dist/release/`.

The generated `latest.json` points to GitHub release asset URLs in `golapress-dist`, using the supplied version string.

## When A Dist Repo Commit Is Enough

A `golapress-dist` commit without a new release is enough when the public change is only in distribution files and does not require a new application binary.

Examples:

- README clarifications
- Docker packaging file changes
- updated installer scripts that download the latest existing binary
- VPS installer documentation updates

In these cases:

1. sync files into `golapress-dist`
2. commit and push `golapress-dist`
3. do not cut a new binary release unless the binary itself must change

## When A New Release Is Required

A new `golapress-dist` release is required when public users need updated application binaries.

Examples:

- backend or frontend application changes in `golapress`
- new app behavior required by released installers
- bug fixes in the binary itself
- any change where `Tools > Updates` should deliver a newer build

In these cases:

1. ensure the desired source changes are committed in `golapress`
2. run `./scripts/build-dist.sh <version>` in `golapress`
3. publish the generated archives and `checksums.txt` as a GitHub release in `golapress-dist`
4. update `latest.json` in `golapress-dist` to match that release
5. commit and push the `latest.json` update in `golapress-dist` if it is tracked there outside the release asset upload step

## Current Practical Rule

Use this rule when deciding whether to release:

- if only `golapress-dist` repo files changed, a dist commit is usually enough
- if the `golapress` binary behavior changed, cut a new `golapress-dist` release

## Why latest.json Matters

The released binary paths are not guessed dynamically. Installers read `latest.json` and follow its URLs.

This matters for:

- the Docker entrypoint installers
- the VPS binary installer
- binary update flows in the admin UI

If `latest.json` still points at old assets, users will keep installing or updating to the old release even if the dist repo has newer scripts or docs.

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

4. copy `dist/release/latest.json` and `dist/release/checksums.txt` into the sibling `golapress-dist/` checkout
5. publish a `golapress-dist` GitHub release using the generated archives and `checksums.txt` from `dist/release/`
6. ensure `latest.json` in `golapress-dist` points at that release version
7. commit and push any tracked dist repo file updates

## VPS Installer Specific Rule

Changes to these public distribution files:

- `scripts/install-vps.sh`
- `docs/vps_binary_install.md`

must be synced into `golapress-dist` if you want public VPS users to see them.

Those changes alone do not automatically require a new binary release.

They do require a new release when the installer depends on behavior that only exists in a newer `golapress` binary.

## Docker Installer Specific Rule

Changes to these files:

- `Dockerfile.standard`
- `Dockerfile.withData`
- `scripts/standard-entrypoint.sh`
- `scripts/with-data-entrypoint.sh`
- `run-standard.sh`
- `run-with-data.sh`

must be synced into `golapress-dist` for public Docker users to receive them.

Those changes do not automatically require a new binary release unless the container should pull a newer application binary.

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
