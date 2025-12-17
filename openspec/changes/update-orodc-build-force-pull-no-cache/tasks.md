## 1. Implementation
- [x] 1.1 Update `bin/orodc` interactive menu for `orodc image build` to include a **Force Pull** option (Stage 1: PHP base image; Stage 2: PHP+Node.js final image).
- [x] 1.2 Implement Force Pull behavior: always run `docker pull` for the selected image even if it exists locally.
- [x] 1.3 Ensure non-interactive behavior remains unchanged.

## 2. Validation
- [x] 2.1 Manually verify interactive prompt shows Force Pull and that it pulls even when the image exists locally.
- [x] 2.2 Run `openspec validate update-orodc-build-force-pull-no-cache --strict`.
