# Change: Add Force Pull option to `orodc image build`

## Why
Interactive `orodc image build` currently offers Pull / Build / Skip for both the PHP base image and the PHP+Node.js final image, but it cannot force-refresh an image when it already exists locally. Users need an explicit **Force Pull** option to always pull the current tag from the registry.

## What Changes
- Add an interactive choice **Force Pull** for both stages in `orodc image build`:
  - Stage 1: PHP base image
  - Stage 2: PHP+Node.js final image
- Force Pull SHALL run `docker pull` for the selected image even if it exists locally.

## Impact
- Affected specs: `openspec/specs/docker-image-management/spec.md`
- Affected code: `bin/orodc` (image build interactive flow)
