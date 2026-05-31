# Why goLaPress?

goLaPress is intentionally conservative about scope.

The main value is not “it does everything.” The main value is that it does the important CMS things in a way that stays understandable and operable.

Practical benefits:

- **Go deployment simplicity**: the app ships as a binary, which keeps install and runtime behavior predictable.
- **Lower operational friction**: fewer moving parts than a typical stack that combines a web app, runtime, plugin ecosystem, and external service sprawl.
- **Bounded extensibility**: plugins and themes have explicit contracts instead of unlimited runtime access.
- **WordPress-like ergonomics**: the admin UI keeps the familiar content-management workflow for editors and site operators.
- **Built-in operator tools**: backups, restore, runtime, updates, and validation are part of the product instead of afterthoughts.
- **Safer automation**: the platform is designed so admin actions can be expressed cleanly through the UI, contracts, and `glp-cli`.

This makes sense if you want:

- a CMS that is easier to deploy and reason about than a large PHP stack
- a product that stays close to content workflows instead of becoming a general platform
- bounded extension points for plugins, themes, and AI assistance
- a system that can be run, restored, and debugged by a small team

It is probably not the best fit if you want:

- a giant marketplace with arbitrary third-party runtime access
- a framework for non-CMS application development
- an unconstrained plugin architecture

For the technical model behind these decisions, see:

- [API And Contracts](api_and_contracts.html)
- [Plugin Development](plugin_development.html)
- [Theme Development](theme_development.html)
- [AI Capabilities](ai_capabilities.html)

