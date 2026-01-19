# Oro Platform Installation Guide

**Complete guide for creating a new Oro Platform project from scratch.**

## Prerequisites

- Complete steps 1-4 from `AGENTS_INSTALLATION_common.md`:
  - Navigate to empty project directory
  - Run `orodc init` manually in terminal (MUST be done by user BEFORE using agent)
  - Run `orodc up -d`
  - Verify containers are running with `orodc ps`

## Installation Steps

### Step 1: Verify Directory is Empty

**REQUIRED**: Ensure directory is empty (or contains only `.git`):

```bash
orodc exec ls -la
# Should show only .git (if version control) or be empty
```

**IMPORTANT**: Project creation commands MUST be run in an empty directory.

### Step 2: Clone Oro Project Repository

Oro projects are cloned from GitHub repositories, not created via composer.

**Option A: OroCommerce**
```bash
orodc exec git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git .
```

**Option B: OroPlatform**
```bash
orodc exec git clone --single-branch --branch 6.1 https://github.com/oroinc/platform-application.git .
```

**Option C: MarelloCommerce**
```bash
# Clone from Marello repository (check latest branch)
orodc exec git clone --single-branch --branch <version> <marello-repo-url> .
```

### Step 3: Install Dependencies

Install PHP dependencies via Composer:

```bash
orodc exec composer install
```

### Step 4: Install Oro Platform

**REQUIRED**: Run Oro installation command:

**IMPORTANT**: The `orodc install` command may prompt for admin credentials. If prompted, ask user for:
- Admin username
- Admin password

Then run installation:

```bash
orodc install
```

This command will:
- Set up database
- Install application
- Configure environment
- Set up initial data (may prompt for admin credentials)

### Step 5: Build Assets

**REQUIRED**: Build frontend assets:

```bash
orodc exec bin/console oro:assets:build default -w
```

### Step 6: Clear and Warm Up Cache

```bash
orodc exec bin/console cache:clear
orodc exec bin/console cache:warmup
```

## Verification

- **Frontend**: `https://{project_name}.docker.local`
- **Admin Panel**: `https://{project_name}.docker.local/admin`
- **Admin Credentials**: Ask user for admin username and password (credentials were set during installation in Step 4 via `orodc install`)

## Important Notes

- **Use git clone**: Oro projects are cloned, not created via composer
- **orodc install**: This is a special OroDC command that handles full installation
- **Assets building**: Always build assets after installation
- **See full guide**: Reference `docs/ORO.md` for complete setup guide and troubleshooting
