# Change: Add custom MySQL images with pv and versioned builds

## Why
MySQL currently relies on upstream images, so pv-based import progress is unavailable and image builds are not aligned with the existing database image workflow.

## What Changes
- Add a MySQL Dockerfile that installs pv and keeps base image compatibility across supported versions
- Add docker-build support for MySQL with version selection and defaults
- Add CI workflow for multi-arch MySQL image publishing
- Update compose configuration to use versioned MySQL images
- Enable pv progress for MySQL imports when available

## Impact
- Affected specs: docker-image-management
- Affected code: compose/docker/mysql, compose/docker-compose-mysql.yml, libexec/orodc/docker-build.sh, libexec/orodc/database/import.sh, .github/workflows, Formula/docker-compose-oroplatform.rb
