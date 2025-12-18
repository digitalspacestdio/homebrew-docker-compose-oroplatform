## 1. Implementation

- [x] 1.1 Add DNS servers to base docker-compose.yml for all services
- [x] 1.2 Add DNS servers to docker-compose-pgsql.yml for database and database-cli services
- [x] 1.3 Add DNS servers to docker-compose-mysql.yml for database and database-cli services
- [x] 1.4 Add DNS servers to docker-compose-proxy.yml for proxy service
- [x] 1.5 Add DNS servers to docker-compose-test.yml for test services (if applicable)
- [x] 1.6 Verify DNS configuration works by testing DNS resolution inside containers

## 2. Validation

- [ ] 2.1 Test DNS resolution from fpm container: `docker exec <fpm> nslookup google.com`
- [ ] 2.2 Test DNS resolution from cli container: `docker exec <cli> nslookup github.com`
- [ ] 2.3 Test DNS resolution from database container: `docker exec <database> nslookup cloudflare.com`
- [ ] 2.4 Verify both DNS servers (1.1.1.1 and 8.8.8.8) are configured in all containers
- [ ] 2.5 Test that internal Docker DNS resolution still works (container name resolution)

