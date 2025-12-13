# Spec: DNS Resolution via Auto /etc/hosts Sync

**Capability:** dns-resolution  
**Change ID:** enhance-proxy-networking  
**Type:** New Capability

## Overview

Automatic DNS resolution for *.docker.local domains via automated /etc/hosts file management. A lightweight daemon watches Docker events and automatically updates /etc/hosts when containers start/stop, eliminating manual DNS configuration. Inspired by [DNS Proxy Server](https://stackoverflow.com/questions/37242217/access-docker-container-from-host-using-containers-name/63656003#63656003).

## ADDED Requirements

### Requirement: DNS-AUTO-SYNC-001 - Automatic /etc/hosts Synchronization

The system MUST automatically synchronize /etc/hosts with running Docker containers that have DNS hostname labels.

#### Scenario: Container Start with DNS Label

**Given** the orodc-dns-sync service is running  
**And** /etc/hosts does not contain entry for "myapp.docker.local"  
**When** a container starts with label `orodc.dns.hostname=myapp.docker.local`  
**Then** an entry `127.0.0.1 myapp.docker.local` MUST be added to /etc/hosts  
**And** the entry MUST be placed between `# OroDC Auto DNS - START` and `# OroDC Auto DNS - END` markers  
**And** the hostname MUST resolve immediately: `ping myapp.docker.local` succeeds  
**And** DNS sync operation MUST be logged

#### Scenario: Container Stop Removes Entry

**Given** /etc/hosts contains entry "127.0.0.1 myapp.docker.local" managed by OroDC  
**And** container "myapp_nginx" with label `orodc.dns.hostname=myapp.docker.local` is running  
**When** the container stops  
**Then** the entry MUST be removed from /etc/hosts  
**And** the hostname MUST no longer resolve  
**And** DNS sync operation MUST be logged

#### Scenario: Multiple Containers with DNS Labels

**Given** the orodc-dns-sync service is running  
**When** three containers start with labels:
- `orodc.dns.hostname=app1.docker.local`
- `orodc.dns.hostname=app2.docker.local`
- `orodc.dns.hostname=app3.docker.local`  
**Then** /etc/hosts MUST contain all three entries  
**And** each entry MUST point to 127.0.0.1  
**And** all hostnames MUST resolve correctly

#### Scenario: No Duplicate Entries

**Given** /etc/hosts contains entry "127.0.0.1 myapp.docker.local"  
**When** another container starts with the same label `orodc.dns.hostname=myapp.docker.local`  
**Then** /etc/hosts MUST contain only ONE entry for myapp.docker.local  
**And** no duplicate entries MUST be created

### Requirement: DNS-DAEMON-001 - DNS Sync Daemon Service

The system MUST provide a background service that watches Docker events and manages /etc/hosts.

#### Scenario: Service Start on Linux (systemd)

**Given** systemd is available  
**And** `/etc/systemd/system/orodc-dns-sync.service` is installed  
**When** the system boots or service is started manually  
**Then** orodc-dns-sync service MUST start automatically  
**And** service MUST watch Docker events API  
**And** service status MUST be visible via `systemctl status orodc-dns-sync`  
**And** logs MUST be available via `journalctl -u orodc-dns-sync`

#### Scenario: Service Start on macOS (launchd)

**Given** launchd is available  
**And** `/Library/LaunchDaemons/com.orodc.dns-sync.plist` is installed  
**When** the system boots or daemon is loaded manually  
**Then** orodc-dns-sync daemon MUST start automatically  
**And** daemon MUST watch Docker events API  
**And** daemon status MUST be visible via `launchctl list | grep orodc`  
**And** logs MUST be available in Console.app

#### Scenario: Service Restart on Failure

**Given** orodc-dns-sync service is running  
**When** the process crashes or dies unexpectedly  
**Then** systemd/launchd MUST automatically restart the service  
**And** /etc/hosts MUST be re-synced on restart  
**And** restart event MUST be logged

#### Scenario: Initial Sync on Service Start

**Given** three containers are already running with DNS labels  
**And** orodc-dns-sync service is not running  
**And** /etc/hosts does not contain OroDC entries  
**When** orodc-dns-sync service starts  
**Then** /etc/hosts MUST be immediately updated with all running containers' hostnames  
**And** all three hostnames MUST resolve correctly

### Requirement: DNS-INSTALL-001 - DNS Service Installation

The system MUST provide commands to install and manage the DNS sync service.

#### Scenario: Install DNS Sync Service (Linux)

**Given** the user runs `orodc proxy-dns-setup --install` on Linux  
**When** the command executes  
**Then** `/usr/local/bin/orodc-dns-sync` script MUST be installed  
**And** `/etc/systemd/system/orodc-dns-sync.service` MUST be created  
**And** the service MUST be enabled and started  
**And** success message MUST be displayed  
**And** service status MUST be checked and reported

#### Scenario: Install DNS Sync Service (macOS)

**Given** the user runs `orodc proxy-dns-setup --install` on macOS  
**When** the command executes  
**Then** `/usr/local/bin/orodc-dns-sync` script MUST be installed  
**And** `/Library/LaunchDaemons/com.orodc.dns-sync.plist` MUST be created  
**And** the daemon MUST be loaded and started  
**And** success message MUST be displayed  
**And** daemon status MUST be checked and reported

#### Scenario: Uninstall DNS Sync Service

**Given** DNS sync service is installed and running  
**When** the user runs `orodc proxy-dns-setup --uninstall`  
**Then** the service MUST be stopped  
**And** all OroDC entries MUST be removed from /etc/hosts (between markers)  
**And** service files MUST be removed (`/etc/systemd/system/orodc-dns-sync.service` or plist)  
**And** script MUST be removed (`/usr/local/bin/orodc-dns-sync`)  
**And** success message MUST be displayed

#### Scenario: Check DNS Sync Status

**Given** DNS sync service may or may not be running  
**When** the user runs `orodc proxy-dns-setup --status`  
**Then** the command MUST report if service is running or not  
**And** if running, MUST show number of managed /etc/hosts entries  
**And** MUST display current OroDC entries from /etc/hosts  
**And** MUST show last sync time if available

### Requirement: DNS-LABEL-001 - Docker Container DNS Labels

The system MUST use Docker labels to identify which containers need DNS entries.

#### Scenario: Container with DNS Label

**Given** a docker-compose.yml contains:
```yaml
services:
  nginx:
    image: nginx
    labels:
      - "orodc.dns.hostname=myapp.docker.local"
```  
**When** the container is started with `docker-compose up`  
**Then** orodc-dns-sync MUST detect the label  
**And** MUST add `127.0.0.1 myapp.docker.local` to /etc/hosts  
**And** hostname MUST resolve to 127.0.0.1

#### Scenario: Container without DNS Label

**Given** a container starts without `orodc.dns.hostname` label  
**When** orodc-dns-sync detects the container start event  
**Then** no /etc/hosts entry MUST be created for this container  
**And** the container is ignored by DNS sync

#### Scenario: Multiple Hostnames per Container

**Given** a container has label `orodc.dns.hostname=app.docker.local,api.docker.local,admin.docker.local`  
**When** the container starts  
**Then** three entries MUST be added to /etc/hosts:
- `127.0.0.1 app.docker.local`
- `127.0.0.1 api.docker.local`
- `127.0.0.1 admin.docker.local`  
**And** all three hostnames MUST resolve correctly

### Requirement: DNS-HOSTS-SAFETY-001 - /etc/hosts File Safety

The system MUST safely manage /etc/hosts without corrupting existing entries.

#### Scenario: Preserve Existing Entries

**Given** /etc/hosts contains existing entries (localhost, custom entries)  
**When** orodc-dns-sync adds OroDC entries  
**Then** existing entries MUST NOT be modified or removed  
**And** OroDC entries MUST be clearly delimited with markers  
**And** /etc/hosts file structure MUST remain valid

#### Scenario: Atomic Updates

**Given** /etc/hosts is being updated by orodc-dns-sync  
**When** multiple container events occur simultaneously  
**Then** updates MUST be atomic (no partial writes)  
**And** /etc/hosts MUST never be in an inconsistent state  
**And** file permissions MUST be preserved (typically 644)

#### Scenario: Marker Management

**Given** orodc-dns-sync manages entries between markers  
**When** the service adds/removes entries  
**Then** `# OroDC Auto DNS - START` marker MUST be present  
**And** `# OroDC Auto DNS - END` marker MUST be present  
**And** all OroDC entries MUST be between these markers  
**And** markers MUST be on separate lines

### Requirement: DNS-VERIFY-001 - DNS Resolution Verification

The system MUST provide verification that DNS resolution is working.

#### Scenario: Verify DNS Setup

**Given** DNS sync service is running  
**And** a container with `orodc.dns.hostname=test.docker.local` is running  
**When** the user runs `orodc proxy-dns-setup --verify`  
**Then** the command MUST test resolution of test.docker.local  
**And** if resolves to 127.0.0.1, MUST report success  
**And** if fails to resolve, MUST report failure with troubleshooting steps

#### Scenario: Verify Troubleshooting

**Given** DNS verification fails  
**When** `orodc proxy-dns-setup --verify` is run  
**Then** the command MUST check if DNS sync service is running  
**And** MUST check if /etc/hosts contains OroDC entries  
**And** MUST suggest starting service if not running  
**And** MUST suggest checking Docker labels if no entries

### Requirement: DNS-INTEGRATION-001 - Integration with Traefik

DNS resolution MUST work seamlessly with Traefik routing.

#### Scenario: End-to-End Traffic Flow

**Given** DNS sync service is running  
**And** Traefik proxy is running on 127.0.0.1:8880  
**And** a container starts with labels:
- `orodc.dns.hostname=myapp.docker.local`
- `traefik.http.routers.myapp.rule=Host(\`myapp.docker.local\`)`  
**When** /etc/hosts is updated with entry  
**And** user runs `curl http://myapp.docker.local:8880`  
**Then** DNS resolution MUST return 127.0.0.1  
**And** request MUST reach Traefik on port 8880  
**And** Traefik MUST route request to container  
**And** response MUST be returned successfully

#### Scenario: HTTPS Traffic

**Given** DNS sync service is running  
**And** Traefik proxy serves HTTPS on 127.0.0.1:8443  
**And** container with hostname myapp.docker.local is running  
**When** user runs `curl -k https://myapp.docker.local:8443`  
**Then** DNS resolution MUST return 127.0.0.1  
**And** HTTPS request MUST reach Traefik  
**And** Traefik MUST serve with wildcard certificate  
**And** response MUST be returned successfully

## MODIFIED Requirements

None - This is a new capability with no modifications to existing requirements.

## REMOVED Requirements

None - This is additive functionality only.

## Dependencies

- Docker API access for event watching
- Sudo/root permissions for /etc/hosts modification
- systemd (Linux) or launchd (macOS) for service management
- Docker labels support in container runtime
- Depends on: ssl-certificate-management (HTTPS integration)

## Testing Requirements

### Unit Tests
- /etc/hosts parsing and modification logic
- Marker-based entry management
- Docker events parsing
- Label extraction from containers
- Atomic file updates

### Integration Tests
- Service starts and watches events
- Container start triggers /etc/hosts update
- Container stop triggers entry removal
- Multiple containers managed correctly
- Service restart resynchronizes
- Existing /etc/hosts entries preserved

### Manual Tests
- Install service on Linux with systemd
- Install service on macOS with launchd
- Start containers with DNS labels
- Verify hostname resolution with `ping`
- Verify browser access via hostname
- Test service restart behavior
- Test service uninstall cleanup

## Acceptance Criteria

- [ ] orodc-dns-sync watches Docker events successfully
- [ ] Container start/stop automatically updates /etc/hosts
- [ ] `orodc proxy-dns-setup --install` installs and starts service
- [ ] Service runs as systemd service (Linux) or launchd daemon (macOS)
- [ ] /etc/hosts entries are properly marked and managed
- [ ] Multiple containers with DNS labels work correctly
- [ ] Service restart resyncs all entries
- [ ] `orodc proxy-dns-setup --uninstall` cleans up completely
- [ ] `orodc proxy-dns-setup --status` shows accurate information
- [ ] `orodc proxy-dns-setup --verify` tests resolution correctly
- [ ] DNS resolution works with Traefik HTTP and HTTPS
- [ ] No existing /etc/hosts entries are corrupted
- [ ] Documentation covers installation and usage
