# AI Agent Playbook

This document is for AI agents and automation that operate inside a goLaPress repo or a goLaPress site.

## Where You Are

You are inside the goLaPress CMS ecosystem.

Canonical public docs entrypoint:

- https://darkgreenev.github.io/golapress-dist/

Before making changes, read:

- [Public Docs Home](README.md)
- [What Is goLaPress?](what_is_golapress.md)
- [Use Cases](use_cases.md)
- [Why goLaPress?](why_golapress.md)
- [AI Capabilities](ai_capabilities.md)
- [API And Contracts](api_and_contracts.md)
- [glp-cli Reference](glp_cli_reference.md)
- [VPS Binary Install](vps_binary_install.md)

If the task touches a plugin or theme, also read that plugin or theme's public docs first.

## Safe Operating Rules

- Prefer core services, hooks, and documented admin routes over guessing internals.
- Prefer `glp-cli` for bounded content, taxonomy, media, navigation, revision, and theme-content workflows.
- Use the admin UI or documented APIs for CMS mutations when possible.
- Do not invent schema names, env keys, plugin contracts, or runtime flags.
- Do not use raw SQL or direct disk mutation for user content unless the docs explicitly say it is supported.
- If a workflow has confirmation, dry-run, or validation steps, use them.

## Assistant-Specific Guidance

- New chats and task flows should be based on the documented provider settings and assistant capabilities.
- If the docs and the UI disagree, check the code and tests before assuming the docs are wrong.
- Keep changes auditable and small.
- When behavior changes, update the public docs so future agents do not have to rediscover the contract.

## When You Are Unsure

1. Inspect the relevant code path.
2. Search the tests for the expected behavior.
3. Read the public docs for the affected subsystem.
4. Make the smallest change that matches the documented contract.
