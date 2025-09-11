# OroDC GitHub Actions Test Suite

This directory contains GitHub Actions workflows for testing OroDC (Oro Docker Compose) functionality across different Oro Platform applications.

## 🧪 Test Workflows

### `test-oro-installations.yml` - Main Installation Tests
**Triggers:** Push, PR, Daily schedule, Manual dispatch

Tests complete installation process for all Oro applications with **automatic latest version detection from GitHub**:
- **Marello Commerce** (latest from GitHub API)
- **OroCRM** (latest from GitHub API) 
- **OroPlatform** (latest from GitHub API)
- **OroCommerce** (latest from GitHub API)

**Features:**
- 🔄 **Dynamic version fetching** from GitHub releases API
- 📦 Matrix-based testing across applications
- ✅ Full installation verification with health checks
- 🎛️ Configurable via workflow dispatch
- 🛡️ Fallback to stable versions if API fails

**Manual Run:**
```bash
# Test specific applications with latest versions
gh workflow run test-oro-installations.yml \
  -f test_applications="marello,orocommerce" \
  -f test_versions="latest"

# Test with specific versions
gh workflow run test-oro-installations.yml \
  -f test_applications="oroplatform" \
  -f test_versions="6.1.4,6.0.9"
```

**Version Detection:**
The workflow automatically fetches the latest stable versions using:
```bash
curl -H 'Authorization: token ${{ github.token }}' \
     -L --silent \
     "https://api.github.com/repos/oroinc/platform/releases" | \
jq -r '.[].tag_name' | \
grep -v '\\-rc[0-9]*\\|\\-beta\\|\\-alpha' | \
head -1
```

## 📊 Test Coverage

| Application | Version Source | PHP | Node.js | Status |
|-------------|----------------|-----|---------|--------|
| Marello | GitHub API (latest) | 8.3 | 20 | ✅ |
| OroCRM | GitHub API (latest) | 8.3 | 20 | ✅ |
| OroPlatform | GitHub API (latest) | 8.3 | 20 | ✅ |
| OroCommerce | GitHub API (latest) | 8.3 | 20 | ✅ |

## 🚀 Running Tests

### Automatic Triggers
- **Daily**: Installation tests (2 AM UTC) with latest versions from GitHub
- **On Push/PR**: Installation tests for code changes

### Manual Execution
```bash
# Test all applications with latest versions
gh workflow run test-oro-installations.yml

# Test specific applications
gh workflow run test-oro-installations.yml \
  -f test_applications="marello,orocommerce" \
  -f test_versions="latest"

# Test with specific versions
gh workflow run test-oro-installations.yml \
  -f test_applications="oroplatform" \
  -f test_versions="6.1.4"
```

### Web Interface
1. Go to **Actions** tab in GitHub repository
2. Select **Test Oro Platform Installations**
3. Click **Run workflow**
4. Configure applications and versions
5. Click **Run workflow**

## 📈 Test Results

### Success Criteria
- ✅ All applications install successfully with latest versions
- ✅ Services start and respond correctly
- ✅ Basic functionality tests pass

### Failure Investigation
1. Check **Summary** section for overview
2. Review **Job logs** for detailed error messages
3. Look for **OroDC logs** in cleanup sections

## 🔧 Configuration

### Test Timeouts
- Service startup: 300 seconds
- Composer install: 600 seconds  
- Application install: 1200 seconds

### Port Allocation
Tests use port prefix `30X` where X = job index to avoid conflicts.

## 🐛 Troubleshooting

### Common Issues

**1. Installation Failures**
```bash
# Check OroDC logs
orodc logs cli
orodc logs fpm
orodc logs database
```

**2. Version Detection Issues**
- GitHub API rate limits may cause fallback to default versions
- Check job logs for "Added to matrix" messages to see resolved versions

**3. Service Startup Issues**
```bash
# Check service status
orodc ps
orodc logs
```

## 📚 Resources

- [OroDC Documentation](../README.md)
- [Oro Platform Documentation](https://doc.oroinc.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Note**: Tests automatically fetch the latest stable versions from GitHub releases API and fall back to known stable versions if needed.
