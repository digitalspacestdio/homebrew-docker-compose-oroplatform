## Why

OroDC has grown from a Bash router into a full development-environment orchestrator with command routing, Docker Compose assembly, project detection, interactive flows, diagnostics, database tooling, proxy management, and Homebrew packaging spread across `bin/orodc` and many shell modules. Rewriting the CLI in TypeScript with oclif gives the project a structured command framework, typed shared logic, stronger testability, and a clearer path for maintaining the command surface as OroDC supports more PHP application types and platforms.

## What Changes

- Replace the Bash-based `orodc` command implementation with a TypeScript + oclif CLI.
- Preserve the public command surface, aliases, environment variable contract, configuration file locations, Docker Compose behavior, and user-facing workflows unless a later spec explicitly marks a behavior as changed.
- Move command routing, argument parsing, environment initialization, Docker Compose command construction, prompts, spinners, process execution, and diagnostics into typed TypeScript modules.
- Keep Docker Compose YAML files, Dockerfiles, image build contexts, doctor configuration files, and project assets as installable data assets rather than rewriting them into code.
- Update Homebrew packaging so `orodc` installs and runs the new Node.js CLI and required static assets.
- Add regression coverage for the current CLI contract before replacing behavior.
- **BREAKING** for maintainers only: command implementation files will no longer be Bash modules under `libexec/orodc/`; downstream scripts that call internal module paths directly are not supported by the new architecture.

## Capabilities

### New Capabilities

- `node-cli-runtime`: TypeScript/oclif runtime, command structure, process execution, asset resolution, packaging, and test contract for the rewritten CLI.

### Modified Capabilities

- `cli-architecture`: Replace the shell module/router architecture requirements with an oclif TypeScript command architecture while preserving public CLI behavior.

## Impact

- Affected code: `bin/orodc`, `libexec/orodc/`, `Formula/docker-compose-oroplatform.rb`, test tooling, generated completion/help behavior, and command documentation.
- Affected assets: `compose/`, Dockerfiles, doctor configs, agent docs, and static scripts must remain distributable through the new package layout.
- Dependencies: Node.js runtime or a bundled Node executable strategy, TypeScript build tooling, oclif packages, and test libraries for command contract coverage.
- Systems: Homebrew installation on macOS/Linux/WSL2, Docker Compose command execution, project config under `.env.orodc` and `~/.orodc`, proxy/certificate workflows, database import/export, and CI validation.
