# WinterCMS Installation Guide

**Note: WinterCMS is the community fork of OctoberCMS. They are compatible and use the same structure.**

**Complete guide for creating a new WinterCMS project from scratch.**

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

### Step 2: Create WinterCMS Project

Create new WinterCMS project using Composer:

```bash
orodc exec composer create-project wintercms/winter .
```

**Note**: You can specify a version/branch:
```bash
orodc exec composer create-project wintercms/winter . "dev-develop"
```

### Step 3: Install Dependencies

```bash
orodc exec composer install
```

### Step 4: Configure Environment

**Option A: Using WinterCMS Environment Setup Command**

```bash
orodc exec artisan winter:env
```

This command will create `.env` file and configure environment variables.

**Option B: Manual Configuration**

Copy environment file and configure:

```bash
orodc exec cp .env.example .env
```

Edit `.env` with database connection details from `orodc exec env | grep ORO_`:
- `DB_HOST` - Database host (usually "database")
- `DB_DATABASE` - Database name
- `DB_USERNAME` - Database user
- `DB_PASSWORD` - Database password
- `DB_CONNECTION` - Database driver (mysql, pgsql, sqlite)

### Step 5: Generate Application Key

**REQUIRED**: Generate application encryption key:

```bash
orodc exec artisan key:generate
```

### Step 6: Run WinterCMS Setup

**Option A: Using Interactive Installer**

```bash
orodc exec artisan winter:install
```

This will run an interactive installer that asks for:
- Database configuration
- Application URL
- Encryption key
- Administrator account details

**Option B: Using Setup Command**

```bash
orodc exec artisan winter:up
```

This command will:
- Run database migrations
- Create initial database structures
- Set up administrator account (if not exists)

### Step 7: Clear and Cache Configuration

```bash
orodc exec artisan config:clear
orodc exec artisan cache:clear
orodc exec artisan config:cache
```

## Verification

- **Application**: `https://{project_name}.docker.local`
- **Admin Panel**: `https://{project_name}.docker.local/backend`
- Check application is accessible and working

## Important Notes

- **Application key**: Always generate application key after creating project
- **Environment configuration**: Always configure `.env` with correct database settings
- **Setup command**: Use `winter:up` to run migrations and create initial structures
- **Interactive installer**: Use `winter:install` for guided setup process
- **Database**: WinterCMS supports MySQL, PostgreSQL, SQLite, and SQL Server
