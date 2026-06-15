---
name: orodc-docker-build-pgsql
description: Build a custom OroDC PostgreSQL image for a version not yet published to GHCR. Use when the user needs a new PostgreSQL version, wants to rebuild orodc-pgsql locally, or PG image is missing from the registry.
license: MIT
metadata:
  author: local
  scope: project
---

# Custom PostgreSQL Image

Build and use `ghcr.io/digitalspacestdio/orodc-pgsql:VERSION` when the needed version is not available in GHCR.

## When to Use

- Required PG version is not in the prebuilt list: `15.1`, `16.6`, `17.4`, `18.4`
- `orodc up` fails pulling `orodc-pgsql`
- User needs PostGIS/pgpool2/repack extensions from the custom Dockerfile

## Quick Build (Preferred)

From any directory:

```bash
orodc docker-build pgsql 19.2
# or
orodc docker-build pgsql --version=19.2
```

Options: `--no-cache`, `--push` (GHCR upload).

## Manual Build

```bash
cd compose/docker/pgsql
docker build --build-arg PG_VERSION=19.2 \
  -t ghcr.io/digitalspacestdio/orodc-pgsql:19.2 .
```

Dockerfile: `compose/docker/pgsql/Dockerfile` — based on official `postgres:VERSION`, auto-installs pgpool2, repack, postgis-3, pv when packages exist.

## Project Configuration

In `.env.orodc` (project or `~/.orodc/<project>/.env.orodc`):

```bash
DC_ORO_DATABASE_SCHEMA=pgsql
DC_ORO_PGSQL_VERSION=19.2
```

PostgreSQL 18+ also needs:

```bash
DC_ORO_PGSQL_DATA_VOLUME_TARGET=/var/lib/postgresql
```

Versions below 18 use `/var/lib/postgresql/data`.

## Apply Changes

```bash
orodc down
orodc up -d
orodc ps
```

Verify: `orodc psql` or `orodc config` shows the new image tag.

## Fully Custom Image Name

`docker-compose-pgsql.yml` uses `ghcr.io/digitalspacestdio/orodc-pgsql:${DC_ORO_PGSQL_VERSION}` — there is no `DC_ORO_PGSQL_IMAGE` override (unlike MySQL).

Options:

1. **Recommended:** build locally with the standard tag above
2. **Override:** create `app/.docker-compose.user.yml`:

```yaml
services:
  database:
    image: myregistry/mypgsql:19.2
  database-cli:
    image: myregistry/mypgsql:19.2
```

## Tap Maintainer Checklist

When adding a version to the repository:

1. Confirm `postgres:VERSION` exists on Docker Hub
2. Build and test: `orodc docker-build pgsql VERSION`
3. Add version to `libexec/orodc/docker-build.sh` (`pgsql` case + `all` loop)
4. Add to `libexec/orodc/init.sh` `PGSQL_VERSIONS` array
5. Bump `Formula/docker-compose-oroplatform.rb` revision
6. `brew reinstall digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform`

## Troubleshooting

| Problem | Action |
|---------|--------|
| Image pull fails | Build locally with `orodc docker-build pgsql VERSION` |
| PostGIS missing after upgrade | Rebuild image; extension install is conditional on apt availability |
| Data dir mismatch PG 17→18 | Set `DC_ORO_PGSQL_DATA_VOLUME_TARGET` correctly before `orodc up` |
| Wrong image still running | `orodc down`, remove old volume if major upgrade, `orodc up -d` |

## References

- `compose/docker/pgsql/README.md`
- `compose/docker/pgsql/Dockerfile`
- `libexec/orodc/docker-build.sh`
