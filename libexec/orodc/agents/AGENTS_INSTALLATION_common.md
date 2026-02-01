# Common Installation Guide

**This guide describes how to create a new OroDC project from scratch (empty directory).**

## Prerequisites

- OroDC must be installed: `brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform`
- Docker must be running
- Empty project directory (or directory with only `.git` if using version control)
- **IMPORTANT**: User must run `orodc init` manually in terminal BEFORE using `orodc codex` agent

## Step-by-Step Installation Process

### 1. Navigate to Project Directory

```bash
cd /path/to/project/directory
```

### 2. Initialize OroDC Environment

**REQUIRED**: Run `orodc init` to configure the OroDC Docker environment:

```bash
orodc init
```

**IMPORTANT**: 
- `orodc init` must be executed by user manually in terminal BEFORE launching `orodc codex`
- `orodc init` is NOT interactive - it requires user to run it manually
- This command will:
  - Detect PHP, Node.js, Composer versions
  - Configure database (PostgreSQL/MySQL)
  - Configure search engine (Elasticsearch/OpenSearch)
  - Configure cache (Redis/Valkey/KeyDB)
  - Configure RabbitMQ
  - Optionally set CMS type

**Important**: This configures the Docker environment, NOT the project codebase itself.

### 3. Start Docker Containers

**REQUIRED**: Start containers before creating project codebase:

```bash
orodc up -d
```

**IMPORTANT**: 
- Nothing starts automatically - you MUST run `orodc up -d` explicitly
- Run `orodc agents common` for detailed explanation of environment workflow

### 4. Verify Containers Are Running

Check container status:

```bash
orodc ps
```

All containers should show "Running" status before proceeding.

### 5. Verify Directory is Empty

**REQUIRED**: Check that directory is empty (or contains only `.git` if using version control):

```bash
# Check directory contents
ls -la
# Should show only .git (if version control) or be empty
```

**IMPORTANT**: Project creation commands (`orodc exec composer create-project` or `orodc exec git clone`) MUST be run in an empty directory.

### 6. Create Project Codebase

**This step is CMS-specific** - run `orodc agents installation` to see detailed instructions for your CMS type:
- Magento: Run `orodc agents installation magento` - uses `orodc exec composer create-project`
- Oro: Run `orodc agents installation oro` - uses `orodc exec git clone`
- Symfony: Run `orodc agents installation symfony` - uses `orodc exec composer create-project`
- Laravel: Run `orodc agents installation laravel` - uses `orodc exec composer create-project`
- WinterCMS: Run `orodc agents installation wintercms` - uses `orodc exec composer create-project`
- Generic PHP: Run `orodc agents installation php-generic` - uses `orodc exec` commands

**IMPORTANT**: 
- Always use `orodc exec` prefix for all commands that create project files
- For composer projects: use `orodc exec composer create-project`
- For git clones: use `orodc exec git clone`
- Follow ALL steps from the CMS-specific installation guide

### 7. Verify Installation

After project creation:
- Check application URL: `https://{project_name}.docker.local`
- Verify containers are still running: `orodc ps`
- Check application logs if needed: `orodc compose logs`

## Important Notes

- **Environment vs Project**: `orodc init` initializes the Docker environment, not the project codebase
- **Containers must be running**: Always run `orodc up -d` before creating project codebase
- **Check status**: Use `orodc ps` to verify containers are running before executing commands
- **Environment variables**: Use `orodc exec env | grep ORO_` to get all OroDC service connection variables (database, cache, search, message queue, etc.)

## Admin Account Creation

- **CRITICAL**: When installation requires admin account data (name, surname, email, username, password), NEVER ask user to provide this information
- **ALWAYS** offer to generate admin credentials automatically instead of requesting them from user
- Generate realistic but secure credentials:
  - Name: "Admin" or "Administrator"
  - Surname: "User" or "Account"
  - Email: "admin@{project_name}.local" or "admin@example.com"
  - Username: "admin" or "administrator"
  - Password: Generate secure random password (12+ characters, mix of letters, numbers, symbols)
- Present generated credentials to user BEFORE using them, allowing user to modify if needed
- Example: "I can generate admin credentials for you. Would you like me to proceed with: Name: Admin, Surname: User, Email: admin@{project_name}.local, Username: admin, Password: [generated secure password]?"

## Troubleshooting

- **Containers not starting**: Check Docker is running, check logs with `orodc compose logs`
- **Port conflicts**: Check if ports are already in use, modify in `.env.orodc` if needed
- **Permission issues**: Ensure Docker has proper permissions
