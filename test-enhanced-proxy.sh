#!/bin/bash
# Integration test for enhanced proxy with HTTPS support
set -e

echo "[TEST] Enhanced Proxy Integration Test"
echo "======================================="

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/compose/docker-compose-proxy.yml"
CONTAINER_NAME="traefik_docker_local"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
}

test_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  exit 1
}

test_info() {
  echo -e "${YELLOW}[INFO]${NC} $1"
}

# Cleanup function
cleanup() {
  test_info "Cleaning up test environment..."
  docker-compose -f "${COMPOSE_FILE}" down -v 2>/dev/null || true
  docker volume rm proxy_certs 2>/dev/null || true
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Test 1: Build and start proxy
test_info "Test 1: Building and starting proxy container..."
cleanup
docker-compose -f "${COMPOSE_FILE}" build --no-cache || test_fail "Failed to build proxy container"
docker-compose -f "${COMPOSE_FILE}" up -d || test_fail "Failed to start proxy container"
test_pass "Proxy container built and started"

# Test 2: Wait for container to be healthy
test_info "Test 2: Waiting for container health check..."
RETRY=0
MAX_RETRIES=30
while [ $RETRY -lt $MAX_RETRIES ]; do
  HEALTH=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "none")
  if [ "$HEALTH" = "healthy" ]; then
    test_pass "Container is healthy"
    break
  fi
  RETRY=$((RETRY + 1))
  sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
  test_fail "Container did not become healthy in time"
fi

# Test 3: Check if certificates were generated
test_info "Test 3: Checking certificate generation..."
docker exec ${CONTAINER_NAME} test -f /certs/ca.crt || test_fail "CA certificate not found"
docker exec ${CONTAINER_NAME} test -f /certs/docker.local.crt || test_fail "Domain certificate not found"
docker exec ${CONTAINER_NAME} test -f /certs/docker.local.key || test_fail "Domain key not found"
test_pass "All certificates generated successfully"

# Test 4: Verify certificate details
test_info "Test 4: Verifying certificate details..."
CERT_ISSUER=$(docker exec ${CONTAINER_NAME} openssl x509 -in /certs/ca.crt -noout -issuer | grep "OroDC Local CA" || echo "")
if [ -z "$CERT_ISSUER" ]; then
  test_fail "CA certificate issuer verification failed"
fi
test_pass "CA certificate issuer verified (OroDC Local CA)"

CERT_SAN=$(docker exec ${CONTAINER_NAME} openssl x509 -in /certs/docker.local.crt -noout -text | grep "DNS:" | grep "docker.local" || echo "")
if [ -z "$CERT_SAN" ]; then
  test_fail "Domain certificate SAN verification failed"
fi
test_pass "Domain certificate SAN verified (*.docker.local)"

# Test 5: Test HTTP endpoint
test_info "Test 5: Testing HTTP endpoint..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8880/api/rawdata 2>/dev/null || echo "000")
if [ "$HTTP_RESPONSE" != "200" ]; then
  test_fail "HTTP endpoint returned status $HTTP_RESPONSE (expected 200)"
fi
test_pass "HTTP endpoint responding (port 8880)"

# Test 6: Test HTTPS endpoint
test_info "Test 6: Testing HTTPS endpoint..."
HTTPS_RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443/api/rawdata 2>/dev/null || echo "000")
if [ "$HTTPS_RESPONSE" != "200" ]; then
  test_fail "HTTPS endpoint returned status $HTTPS_RESPONSE (expected 200)"
fi
test_pass "HTTPS endpoint responding (port 8443)"

# Test 7: Verify HTTPS certificate
test_info "Test 7: Verifying HTTPS certificate from endpoint..."
CERT_CN=$(echo | openssl s_client -connect localhost:8443 -servername test.docker.local 2>/dev/null | openssl x509 -noout -subject | grep "docker.local" || echo "")
if [ -z "$CERT_CN" ]; then
  test_fail "HTTPS certificate verification failed"
fi
test_pass "HTTPS certificate verified (*.docker.local)"

# Test 8: Check Traefik version (should be v3)
test_info "Test 8: Checking Traefik version..."
TRAEFIK_VERSION=$(docker exec ${CONTAINER_NAME} traefik version 2>/dev/null | grep "Version:" | grep -o "v[0-9]*" || echo "")
if [[ ! "$TRAEFIK_VERSION" =~ ^v3 ]]; then
  test_fail "Traefik version is $TRAEFIK_VERSION (expected v3.x)"
fi
test_pass "Traefik version verified ($TRAEFIK_VERSION)"

# Test 9: Check s6-overlay is working
test_info "Test 9: Checking s6-overlay process management..."
docker exec ${CONTAINER_NAME} s6-rc -a list >/dev/null 2>&1 || test_fail "s6-overlay not functioning"
test_pass "s6-overlay process manager working"

# Test 10: Verify SOCKS5 is disabled by default
test_info "Test 10: Verifying SOCKS5 is disabled by default..."
SOCKS5_PROCESS=$(docker exec ${CONTAINER_NAME} ps aux | grep socks5 | grep -v grep || echo "")
if [ -n "$SOCKS5_PROCESS" ]; then
  test_fail "SOCKS5 is running but should be disabled by default"
fi
test_pass "SOCKS5 correctly disabled by default"

echo ""
echo "======================================="
echo -e "${GREEN}All tests passed!${NC}"
echo "======================================="

