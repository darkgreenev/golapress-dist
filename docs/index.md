---
layout: default
title: goLaPress Dist Docs
---

# goLaPress Dist Docs

Public documentation for installers, operators, plugin authors, theme authors, and AI tools.

## Start Here For AI Assistants And Operators

If you are operating, extending, or automating a goLaPress install, use this page as the canonical entrypoint.

Core rules:

- Prefer documented admin workflows first.
- Prefer documented HTTP and JSON API surfaces over direct database writes.
- Do not mutate site content directly in MySQL or SQLite unless you are doing an explicit migration or recovery task.
- Treat theme activation, plugin changes, settings changes, updates, rollbacks, and content deletion as high-risk actions that require explicit confirmation.
- After making changes, verify the affected URL, API result, or runtime status before claiming success.

## Quick Paths

Use these docs depending on the task:

- Installing or restarting a public VPS or binary release:
  [VPS binary install](vps_binary_install.md)
- Understanding what the built-in assistant can safely rely on:
  [AI capabilities](ai_capabilities.md)
- Finding public HTTP routes, JSON API families, plugin RPC contracts, and site layout:
  [API and contracts](api_and_contracts.md)
- Building or fixing themes against the real runtime template contract:
  [Theme development](theme_development.md)
- Building plugins with the public plugin contract:
  [Plugin development](plugin_development.md)
- Looking up lifecycle hooks and payload names:
  [Hook reference](hook_reference.md)
- Understanding the dist release workflow and GitHub Pages publication flow:
  [Dist release workflow](dist_release_workflow.md)

## Safe Ways To Change Things

For content and site operations, prefer this order:

1. admin UI workflows
2. documented JSON APIs under `/api/v1/`
3. plugin and theme extension contracts
4. direct file edits in site-owned `themes/` and `plugins/`

Avoid using raw database access as the normal integration surface.

## Restart Guidance By Environment

- Development checkout: use the repo development entrypoint for that checkout.
- Installed binary release with `systemd`: use `systemctl restart golapress`.
- Installed binary release without `systemd`: use the installer-managed launcher and PID/log files documented in [VPS binary install](vps_binary_install.md).
- Containerized runtime: use the configured container or orchestrator restart flow.

## Site-Owned Paths

The main site-owned areas are:

- `data/`
- `themes/`
- `plugins/`

On VPS installs, the goLaPress binary is usually outside the site directory. That separation is intentional and should be preserved during automation.

## Install

- [VPS binary install](vps_binary_install.md)

## Release Workflow

- [Dist release workflow](dist_release_workflow.md)

## AI

- [AI capabilities](ai_capabilities.md)

## API And Contracts

- [API and contracts](api_and_contracts.md)
- [Hook reference](hook_reference.md)

## Development

- [Plugin development](plugin_development.md)
- [Theme development](theme_development.md)
