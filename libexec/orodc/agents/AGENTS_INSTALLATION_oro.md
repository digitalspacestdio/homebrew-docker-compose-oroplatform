# Oro Platform Installation Guide

**Complete guide for creating a new Oro Platform project from scratch.**

## Prerequisites

- Complete steps 1-4 from `orodc agents installation` (common part):
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

### Step 2: Create Oro Project

Choose one of the following methods:

#### Method 1: Clone from GitHub (Recommended)

Oro projects can be cloned from GitHub repositories:

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

#### Method 2: Create via Composer (CE Edition Only)

**IMPORTANT**: Composer create-project installs **Community Edition (CE)** only.

**OroCommerce CE:**
```bash
orodc exec composer create-project oro/commerce-application .
```

**OroPlatform CE:**
```bash
orodc exec composer create-project oro/platform-application .
```

**For Enterprise Edition**: Enterprise versions require access to private Oro repositories and cannot be installed via public composer create-project. Use git clone from your Enterprise repository or contact Oro support for Enterprise installation instructions.

### Step 3: Install Dependencies

Install PHP dependencies via Composer:

```bash
orodc exec composer install
```

### Step 4: Install Oro Platform

**REQUIRED**: Run Oro installation command:

**IMPORTANT**: Before running installation:
- **NEVER** ask user to provide admin credentials
- **ALWAYS** offer to generate admin credentials automatically:
  - Name: "Admin"
  - Surname: "User"
  - Email: "admin@{project_name}.local"
  - Username: "admin"
  - Password: Generate secure random password (12+ characters)
- Present generated credentials to user BEFORE using them, allowing user to modify if needed

Then run installation with generated credentials:

```bash
orodc exec bin/console oro:install \
  --env=prod \
  --timeout=1800 \
  --language=en \
  --formatting-code=en_US \
  --organization-name="Acme Inc." \
  --user-name="admin" \
  --user-email="admin@{project_name}.local" \
  --user-firstname="Admin" \
  --user-lastname="User" \
  --user-password="<GENERATED_SECURE_PASSWORD>" \
  --application-url="https://{project_name}.docker.local/" \
  --sample-data=y
```

**Parameters explanation:**
- `--env=prod` - Production environment
- `--timeout=1800` - Installation timeout (30 minutes)
- `--language=en` - Default language
- `--formatting-code=en_US` - Locale for formatting
- `--organization-name` - Organization name (can be customized)
- `--user-name` - Admin username (generated: "admin")
- `--user-email` - Admin email (generated: "admin@{project_name}.local")
- `--user-firstname` - Admin first name (generated: "Admin")
- `--user-lastname` - Admin last name (generated: "User")
- `--user-password` - Admin password (generated secure password)
- `--application-url` - Application base URL
- `--sample-data=y` - Install with sample data (use `--sample-data=n` for installation without demo data)

This command will:
- Set up database
- Install application
- Configure environment
- Set up initial data with generated admin account

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
- **Admin Credentials**: Credentials were generated during installation in Step 4 via `orodc exec bin/console oro:install` (if user modified them, they should have been noted)

## Important Notes

- **Installation methods**: Oro projects can be cloned from GitHub or created via composer (CE only)
- **CE vs Enterprise**: `composer create-project` installs Community Edition (CE) only. For Enterprise Edition, use git clone from Enterprise repository or contact Oro support
- **Installation command**: Use `orodc exec bin/console oro:install` with all required parameters (see Step 4 for full example)
- **Assets building**: Always build assets after installation
- **See full guide**: Reference `docs/ORO.md` for complete setup guide and troubleshooting
