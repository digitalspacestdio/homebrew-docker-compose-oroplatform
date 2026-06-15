# `orodc agents`

Internal reference. Read this when a task depends on project conventions, CMS-specific behavior, or installation guides.

Run `orodc status` first to confirm you are in a real application project root and to learn the environment state. Do not treat a missing `.env.orodc` by itself as a problem.

Then run `orodc agents` from the real application project root. Do not rely on `orodc agents` from the tap repository itself or from an arbitrary non-project directory.

Main commands:

```bash
orodc agents common
orodc agents rules
orodc agents installation
orodc agents <cms-type>
```

- `orodc agents common`: shared guidance for all projects
- `orodc agents rules`: coding rules for the detected CMS
- `orodc agents installation`: installation guide for the detected CMS
- `orodc agents <cms-type>`: CMS-specific instructions such as `oro`, `magento`, `symfony`, `laravel`, `wintercms`, or `php-generic`

Rules:

- Start with `orodc agents` when the task depends on project conventions or CMS-specific behavior.
- If the user asks to install, set up, deploy, or create a CMS project, read `orodc agents installation` first and follow it step by step.
