# Laravel Installation Guide

**Complete guide for creating a new Laravel project from scratch.**

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

### Step 2: Create Laravel Project

Create new Laravel project using Composer:

```bash
orodc exec composer create-project laravel/laravel .
```

### Step 3: Install Dependencies

```bash
orodc exec composer install
```

### Step 4: Configure Environment

Copy environment file and configure:

```bash
orodc exec cp .env.example .env
```

Edit `.env` with database connection details from `orodc exec env | grep ORO_`:
- `DB_HOST` - Database host (usually "database")
- `DB_DATABASE` - Database name
- `DB_USERNAME` - Database user
- `DB_PASSWORD` - Database password

### Step 5: Generate Application Key

**REQUIRED**: Generate application encryption key:

```bash
orodc exec artisan key:generate
```

### Step 6: Run Database Migrations

```bash
orodc exec artisan migrate
```

### Step 7: Clear and Cache Configuration

```bash
orodc exec artisan config:clear
orodc exec artisan cache:clear
orodc exec artisan config:cache
```

## Verification

- **Application**: `https://{project_name}.docker.local`
- Check application is accessible and working

## Important Notes

- **Application key**: Always generate application key after creating project
- **Environment configuration**: Always configure `.env` with correct database settings
- **Migrations**: Run migrations to set up database schema
