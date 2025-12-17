# Change: Add Force Pull option to `orodc image build`

## Why
Interactive `orodc image build` currently offers Pull / Build / Skip for the PHP base image, but it cannot force-refresh the base image when it already exists locally. Users need an explicit **Force Pull** option to always pull the current tag from the registry.

## What Changes
- Add an interactive choice **Force Pull** for the PHP base image stage in `orodc image build`.
- Force Pull SHALL run `docker pull` for the base image even if it exists locally.

## Impact
- Affected specs: `openspec/specs/docker-image-management/spec.md`
- Affected code: `bin/orodc` (image build interactive flow)
