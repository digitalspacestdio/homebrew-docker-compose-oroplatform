# Symfony Installation Guide

**Complete guide for creating a new Symfony project from scratch.**

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

### Step 2: Create Symfony Project

Create new Symfony project using Symfony installer or Composer:

**Option A: Using Symfony CLI (if available)**
```bash
orodc exec symfony new . --version="6.4" --webapp
```

**Option B: Using Composer**
```bash
orodc exec composer create-project symfony/skeleton .
orodc exec composer require symfony/console symfony/framework-bundle symfony/web-server-bundle
```

**Option C: Using Symfony Website Skeleton (with webapp)**
```bash
orodc exec composer create-project symfony/website-skeleton .
```

### Step 3: Install Dependencies

```bash
orodc exec composer install
```

### Step 4: Configure Environment

Copy environment file and configure:

```bash
orodc exec cp .env .env.local
```

Edit `.env.local` with database connection details from `orodc exec env | grep ORO_`:
- `DATABASE_URL` - Use database connection from environment variables

### Step 5: Create Database Schema

```bash
orodc exec bin/console doctrine:database:create
orodc exec bin/console doctrine:schema:create
```

Or use migrations:

```bash
orodc exec bin/console make:migration
orodc exec bin/console doctrine:migrations:migrate
```

### Step 6: Clear Cache

```bash
orodc exec bin/console cache:clear
orodc exec bin/console cache:warmup
```

## Verification

- **Application**: `https://{project_name}.docker.local`
- Check application is accessible and working

## Important Notes

- **Choose skeleton**: Select appropriate Symfony skeleton based on project needs
- **Environment configuration**: Always configure `.env.local` with correct database settings
- **Database setup**: Create database schema before running application
