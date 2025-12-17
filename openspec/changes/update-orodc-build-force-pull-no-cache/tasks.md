## 1. Implementation
- [x] 1.1 Update `bin/orodc` interactive menu for `orodc image build` (Stage 1: PHP base image) to include a **Force Pull** option.
- [x] 1.2 Implement Force Pull behavior: always run `docker pull ${PHP_BASE_TAG}` even if the image exists locally.
- [x] 1.3 Ensure non-interactive behavior remains unchanged.

## 2. Validation
- [x] 2.1 Manually verify interactive prompt shows Force Pull and that it pulls even when the image exists locally.
- [x] 2.2 Run `openspec validate update-orodc-build-force-pull-no-cache --strict`.
