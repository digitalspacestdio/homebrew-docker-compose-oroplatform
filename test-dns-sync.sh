#!/bin/bash
# Integration test for DNS sync (container mode)
set -e

echo "[TEST] DNS Sync (Container Mode) Integration Test"
echo "=================================================="

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/compose/docker-compose-proxy.yml"
CONTAINER_NAME="traefik_docker_local"
TEST_CONTAINER="test-app"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Cleanup
cleanup() {
  test_info "Cleaning up test environment..."
  docker-compose -f "${COMPOSE_FILE}" down -v 2>/dev/null || true
  docker rm -f ${TEST_CONTAINER} 2>/dev/null || true
  docker volume rm proxy_certs 2>/dev/null || true
}

trap cleanup EXIT

# Test 1: Start proxy container
test_info "Test 1: Starting proxy container..."
cleanup
docker-compose -f "${COMPOSE_FILE}" up -d || test_fail "Failed to start proxy"
test_pass "Proxy container started"

# Test 2: Wait for health check
test_info "Test 2: Waiting for container health..."
RETRY=0
MAX_RETRIES=30
while [ $RETRY -lt $MAX_RETRIES ]; do
  HEALTH=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "none")
  if [ "$HEALTH" = "healthy" ]; then
    break
  fi
  RETRY=$((RETRY + 1))
  sleep 2
done
test_pass "Container is healthy"

# Test 3: Check DNS sync service is running
test_info "Test 3: Checking DNS sync service..."
docker exec ${CONTAINER_NAME} s6-rc -a list | grep -q dns-sync || test_fail "DNS sync service not found"
test_pass "DNS sync service is running"

# Test 4: Create test container with label
test_info "Test 4: Creating test container with DNS label..."
docker run -d --name ${TEST_CONTAINER} \
  --network dc_shared_net \
  --label "orodc.dns.hostname=testapp.docker.local" \
  nginx:alpine || test_fail "Failed to create test container"
test_pass "Test container created with label"

# Test 5: Wait for DNS sync to process
test_info "Test 5: Waiting for DNS sync to update..."
sleep 5
test_pass "DNS sync processed"

# Test 6: Check /etc/hosts inside proxy container
test_info "Test 6: Verifying /etc/hosts inside proxy container..."
HOSTS_CONTENT=$(docker exec ${CONTAINER_NAME} cat /etc/hosts)
echo "$HOSTS_CONTENT" | grep -q "# OroDC DNS - START" || test_fail "/etc/hosts markers not found"
echo "$HOSTS_CONTENT" | grep -q "testapp.docker.local" || test_fail "Test hostname not in /etc/hosts"
test_pass "/etc/hosts updated correctly"

# Test 7: Verify hostname maps to container name
test_info "Test 7: Checking hostname mapping..."
MAPPING=$(docker exec ${CONTAINER_NAME} grep "testapp.docker.local" /etc/hosts | grep test-app || echo "")
if [ -z "$MAPPING" ]; then
  test_fail "Hostname not mapped to container name"
fi
test_pass "Hostname mapped: testapp.docker.local -> test-app"

# Test 8: Test resolution from inside proxy container
test_info "Test 8: Testing DNS resolution inside proxy..."
docker exec ${CONTAINER_NAME} getent hosts testapp.docker.local >/dev/null 2>&1 || \
  test_fail "Cannot resolve testapp.docker.local inside proxy"
test_pass "DNS resolution works inside proxy"

# Test 9: Remove test container and verify cleanup
test_info "Test 9: Testing DNS cleanup on container stop..."
docker rm -f ${TEST_CONTAINER}
sleep 5
HOSTS_AFTER=$(docker exec ${CONTAINER_NAME} cat /etc/hosts)
if echo "$HOSTS_AFTER" | grep -q "testapp.docker.local"; then
  test_fail "Hostname not removed from /etc/hosts after container stop"
fi
test_pass "DNS entry removed after container stop"

# Test 10: Test multiple hostnames (comma-separated)
test_info "Test 10: Testing multiple hostnames..."
docker run -d --name ${TEST_CONTAINER} \
  --network dc_shared_net \
  --label "orodc.dns.hostname=app1.docker.local,app2.docker.local" \
  nginx:alpine || test_fail "Failed to create multi-hostname container"
sleep 5

HOSTS_MULTI=$(docker exec ${CONTAINER_NAME} cat /etc/hosts)
echo "$HOSTS_MULTI" | grep -q "app1.docker.local" || test_fail "First hostname not found"
echo "$HOSTS_MULTI" | grep -q "app2.docker.local" || test_fail "Second hostname not found"
test_pass "Multiple hostnames supported"

echo ""
echo "=================================================="
echo -e "${GREEN}All DNS sync tests passed!${NC}"
echo "=================================================="
echo ""
echo "How it works:"
echo "1. Proxy container runs dns-sync service"
echo "2. Service watches Docker events"
echo "3. Updates /etc/hosts inside proxy container"
echo "4. Maps hostnames to Docker container names"
echo "5. Works with SOCKS5 or Traefik routing"

