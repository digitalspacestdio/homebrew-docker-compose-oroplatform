# PostgreSQL Custom Image

This directory contains a custom Dockerfile for PostgreSQL with automatic pgpool2 installation.

## Features

- **Dynamic Version Detection**: Automatically detects the PostgreSQL major version from the base image
- **Conditional pgpool2 Installation**: Installs `postgresql-XX-pgpool2` if available in the repository
- **Graceful Fallback**: Skips pgpool2 installation if the package is not available for the current version

## Build Arguments

- `PG_VERSION`: PostgreSQL version to use (default: `15.1`)
  - Examples: `15.1`, `16.2`, `17.4`
  - The Dockerfile will automatically extract the major version (15, 16, 17) for pgpool2 package selection

## Usage

The image is automatically built when using `docker-compose up` with the pgsql profile.

### Environment Variables

Control the PostgreSQL version via environment variable:

```bash
export DC_ORO_PGSQL_VERSION=17.4
orodc up -d
```

### Manual Build

To build the image manually:

```bash
cd compose/docker/pgsql
docker build --build-arg PG_VERSION=17.4 -t custom-postgres:17.4 .
```

## How It Works

1. The Dockerfile uses the official `postgres` image as the base
2. During build, it runs `pg_config --version` to extract the major version
3. It checks if `postgresql-${PG_MAJOR}-pgpool2` package exists in the Debian repository
4. If available, it installs the package; otherwise, it skips installation
5. The build process is optimized with proper cleanup to minimize image size

## Package Availability

- PostgreSQL 15: `postgresql-15-pgpool2` ✅
- PostgreSQL 16: `postgresql-16-pgpool2` ✅
- PostgreSQL 17: `postgresql-17-pgpool2` ✅
- PostgreSQL 14: `postgresql-14-pgpool2` ✅

Note: Package availability depends on the Debian/Ubuntu version in the base postgres image.

## Maintenance

The Dockerfile is designed to be version-agnostic and should work with future PostgreSQL versions without modifications.

