# 🧪 Local OroDC Testing

This guide describes various methods for testing OroDC locally.

## 🚀 Quick Command Tests

### Prerequisites
- Installed OroDC (`brew install digitalspacestdio/docker-compose-oroplatform/docker-compose-oroplatform`)
- Directory with existing Oro application

### Testing in existing project
```bash
# Navigate to Oro application directory
cd ~/orocommerce  # or ~/marello, ~/orocrm, etc.

# Test basic commands
orodc version                    # OroDC version
orodc --version                  # PHP version
orodc help                       # Help information
orodc ps                         # Container status
orodc config --quiet             # Configuration check
```

## 🏗️ Full Installation Testing

### Manual testing
For complete installation testing, manually clone and test applications:

```bash
# Clone application
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/platform-application.git ~/test-oroplatform
cd ~/test-oroplatform

# Configure OroDC
echo "DC_ORO_NAME=test-oroplatform" > .env.orodc
echo "DC_ORO_PORT_PREFIX=301" >> .env.orodc
echo "DC_ORO_MODE=ssh" >> .env.orodc

# Install and start
orodc install && orodc up -d

# Test web interface
curl -I http://localhost:30180

# Cleanup
orodc down --volumes --remove-orphans
cd .. && rm -rf ~/test-oroplatform
```

### Supported applications:
- **marello** - https://github.com/marellocommerce/marello-application.git
- **orocommerce** - https://github.com/oroinc/orocommerce-application.git
- **oroplatform** - https://github.com/oroinc/platform-application.git
- **orocrm** - https://github.com/oroinc/crm-application.git

## 🐳 GitHub Actions Locally (Act)

### Act Installation
```bash
# Act is already installed in the system
act --version
```

### GitHub Token Setup
```bash
# Create .secrets file (already configured)
echo 'GITHUB_TOKEN=your_token_here' > .secrets
```

### Running Tests
```bash
# Test installation workflow
act workflow_dispatch -W .github/workflows/test-oro-installations.yml \
    -j test-installation \
    --matrix application:oroplatform \
    --matrix version:6.1.4 \
    --matrix repo_url:https://github.com/oroinc/platform-application.git \
    --secret-file .secrets
```

## 📊 Method Comparison

| Method | Speed | Completeness | Requirements |
|--------|-------|--------------|--------------|
| **Quick commands** | ⚡ Seconds | 🔍 Basic | Existing project |
| **Manual testing** | ⏳ 10-20 min | ✅ Complete | Docker, Git |
| **Act** | ⏳ 20+ min | ✅ Complete | Act, GitHub token |

## 🛠️ Recommendations

### For OroDC development:
1. **Quick commands** - for basic functionality checks
2. **Manual testing** - for complete installation verification
3. **Act** - for workflow testing

### For CI/CD:
- Use GitHub Actions in cloud for complete testing
- Act is suitable for local workflow debugging

## 🐛 Troubleshooting

### Manual testing not working:
```bash
# Check Docker
docker --version
docker compose version

# Check OroDC
orodc version

# Check Git
git --version
```

### Act not working:
```bash
# Check installation
act --version

# Check token
cat .secrets

# Check Docker
docker ps
```

### Port conflicts:
```bash
# Stop all OroDC projects
orodc down --remove-orphans

# Or use different port prefix
echo "DC_ORO_PORT_PREFIX=301" >> .env.orodc
```

## 📝 Usage Examples

### Testing new feature:
```bash
# 1. Quick command check
cd ~/orocommerce && orodc --version

# 2. Manual installation test
git clone --single-branch --branch 6.1.4 https://github.com/oroinc/orocommerce-application.git ~/test-orocommerce
cd ~/test-orocommerce
echo "DC_ORO_MODE=ssh" > .env.orodc
orodc install && orodc up -d

# 3. Workflow test
act workflow_dispatch -W .github/workflows/test-oro-installations.yml --secret-file .secrets
```

### Debugging issue:
```bash
# Test with debug
cd ~/test-orocommerce
DEBUG=1 orodc install

# Check logs
orodc logs
```

---

**💡 Tip**: Start with quick commands, then proceed to full testing only when necessary.