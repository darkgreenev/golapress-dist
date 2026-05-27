# AI Capabilities

This document describes the current built-in AI assistant surface in goLaPress, with an emphasis on what operators and AI agents can rely on in public installs from `golapress-dist`.

## What The Built-In Assistant Is

The built-in assistant is a Codex-backed admin tool. It runs inside goLaPress admin and talks to the Codex CLI through the local or Docker runtime bridge.

It is intended to be:

- bounded
- auditable
- admin-focused
- useful for content and site operations

It is not intended to be an unrestricted system shell or a replacement for explicit admin workflows.

## Supported Runtimes

goLaPress currently supports these Codex runtimes:

- `local`: goLaPress launches the `codex` command on the host machine
- `docker`: goLaPress talks to the separate Codex worker container

For public non-Docker VPS installs, use `local`.

## Authentication Options

The assistant can authenticate Codex in either of these ways:

- a saved OpenAI API key in `Settings > System`
- an existing Codex CLI login for the same OS user that runs goLaPress

For current Codex CLI releases, the login command is:

```bash
codex login
```

When goLaPress runs as `root` under a VPS install, use:

```bash
sudo codex login
```

## Current Admin UI Capabilities

Today the built-in assistant and adjacent AI features can reliably help with:

- AI chat in admin
- theme import assistance
- active theme fix workflows
- guided recipe drafting for page-builder flows
- operator guidance about Codex login and API-key setup

The wider admin product surface that an AI agent can read, explain, and help operators navigate includes:

- posts
- pages
- categories
- tags
- comments
- menus
- media
- users
- themes
- plugins
- site settings
- backups
- binary updates

That does not mean the assistant has a stable, first-class tool call for every one of those actions yet. In many cases the current value is guidance, code-aware assistance, and workflow help inside admin rather than direct autonomous mutation.

## What AI Agents Should Prefer

When an AI agent is operating inside a public goLaPress install or repo checkout, prefer this order:

1. documented admin workflows
2. documented HTTP/API surfaces
3. plugin and theme contracts
4. direct file edits inside site-owned themes and plugins

Avoid treating raw database access as the primary integration surface unless you are writing a controlled migration or recovery tool.

## High-Risk Actions

The following actions should be treated as high risk and should usually require explicit operator confirmation:

- deleting content
- changing the active theme
- enabling, disabling, installing, replacing, or deleting plugins
- changing sitewide settings
- changing authentication settings
- performing updates or rollbacks
- editing live theme templates

## Filesystem Areas AI Can Reason About

On a standard site install, the public, site-owned areas are:

- `data/`
- `themes/`
- `plugins/`

On VPS installs, the application binary is separate from the site directory. This makes it safer for operators and AI tools to inspect or change site-owned themes and plugins without overwriting the app binary itself.

## Themes And Plugins

The assistant is most useful when the public extension contracts are present in the checkout. For that reason, `golapress-dist/docs/` should include:

- plugin development guidance
- theme development guidance
- hook names and payloads
- route and API contracts

See:

- [Plugin Development](plugin_development.html)
- [Theme Development](theme_development.html)
- [Hook Reference](hook_reference.html)
- [API And Contracts](api_and_contracts.html)

## Practical Remote-Server Setup

For a non-Docker VPS install:

1. install `@openai/codex`
2. run `sudo codex login` or save an API key in admin
3. enable Codex in `Settings > System`
4. choose runtime `Local`
5. start a new assistant chat

If the assistant UI reports that Codex is unauthenticated, start a new chat after completing the login flow.
