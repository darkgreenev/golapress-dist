# Private Plugin Distribution

This document defines the supported path for agencies, freelancers, technical teams, and advanced operators who want to build their own goLaPress plugins and share them outside the official goLaPress catalog.

This is a supported workflow.

It is not a public marketplace design.

## Product Boundary

goLaPress supports two separate plugin distribution paths:

- official catalog plugins
- private native plugin packages

Official catalog plugins are curated and distributed through the public goLaPress plugin catalog.

Private native plugin packages are created and shared by third parties directly. They are not part of the official catalog unless they are later curated and published there.

## Who This Is For

This path is meant for:

- agencies extending client sites
- freelancers shipping custom integrations
- technical teams maintaining internal plugins
- advanced operators who can manage plugin binaries safely

This path is not meant to be an in-app plugin builder for non-technical operators.

## Supported Plugin Type

Third-party plugins should usually be `binary` plugins.

Each plugin should live in its own repository and produce its own release artifacts.

## Supported Package Formats

goLaPress supports installing native plugin packages as:

- `.zip`
- `.tar.gz`
- `.tgz`

Each archive should contain exactly one plugin.

## Required Package Shape

A shareable package should contain one plugin directory with:

- `plugin.json`
- the compiled executable declared by `plugin.json`
- any other runtime files the plugin needs

Example:

```text
my-plugin/
├── plugin.json
├── my-plugin
└── assets/
```

The manifest must be valid and the plugin ID must be unique on the target site.

## Platform Reality

Private native plugin packages are usually platform-specific because they ship compiled binaries.

That means a plugin author should usually publish separate packages for different targets, for example:

- Linux amd64
- Linux arm64
- Windows amd64

An operator should install the package that matches the server where goLaPress runs.

## Trust Model

Private plugin packages are operator-trusted software.

Installing one means the operator is choosing to allow that plugin binary to run on the site server.

goLaPress validates package structure and manifest rules, but that does not turn uploaded third-party plugins into curated official plugins.

## Recommended Author Workflow

1. Create the plugin in its own repository.
2. Implement the plugin as a `binary` plugin.
3. Build the executable for the target platform.
4. Assemble one plugin directory with `plugin.json` and the executable.
5. Package that directory as `.zip` or `.tar.gz`.
6. Test the package on a `golapress-dist` install or released binary install.
7. Share the package directly with operators or clients.

## Recommended Release Conventions

For private plugin distribution, use a predictable release pattern:

- semantic versions in `plugin.json`
- one archive per plugin package
- per-platform artifacts when needed
- changelog notes
- checksums for distributed artifacts

If a team manages many sites, it can later add its own private release index or artifact store. That is separate from the public goLaPress catalog.

## What goLaPress Should Not Promise Here

This workflow does not imply:

- a public marketplace
- a plugin submission system
- automatic trust of third-party uploads
- in-app plugin code authoring for general operators
- hot-swapping complex plugin runtimes in-process

The goal is a conservative, useful private-plugin path, not platform sprawl.
