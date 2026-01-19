#!/bin/bash
# dns-sync.sh - Auto-sync Docker container hostnames to /etc/hosts INSIDE proxy container
# This runs INSIDE the proxy container and updates its own /etc/hosts

set -euo pipefail

# Configuration
HOSTS_FILE="/etc/hosts"
MARKER_START="# OroDC DNS - START"
MARKER_END="# OroDC DNS - END"
LABEL_NAME="orodc.dns.hostname"
DOCKER_SOCK="/var/run/docker.sock"

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DNS-SYNC] $*"
}

# Extract hostnames from Traefik rule
extract_hosts_from_rule() {
    local rule="$1"
    # Extract all Host(`hostname`) patterns from Traefik rule
    echo "$rule" | grep -oE 'Host\(`[^`]+`\)' | sed -E 's/Host\(`([^`]+)`\)/\1/g'
}

# Update /etc/hosts with container DNS names
update_hosts() {
    log "Updating /etc/hosts inside container..."
    
    # Use associative array to deduplicate hostnames
    declare -A host_map
    
    # Use docker CLI if available
    if command -v docker >/dev/null 2>&1; then
        # Get all running containers with Traefik enabled
        while IFS= read -r container_id; do
            if [[ -z "$container_id" ]]; then
                continue
            fi
            
            container_name=$(docker inspect -f "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///' || echo "")
            
            # Get IP from dc_shared_net network (preferred) or first available network
            container_ip=$(docker inspect -f "{{.NetworkSettings.Networks.dc_shared_net.IPAddress}}" "$container_id" 2>/dev/null || echo "")
            if [[ -z "$container_ip" ]] || [[ "$container_ip" == "<no value>" ]]; then
                container_ip=$(docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{break}}{{end}}" "$container_id" 2>/dev/null || echo "")
            fi
            
            # For proxy container, use 127.0.0.1 (Traefik listens on localhost)
            if [[ "$container_name" == "proxy" ]]; then
                container_ip="127.0.0.1"
            fi
            
            if [[ -z "$container_name" ]]; then
                continue
            fi
            
            # Method 1: Check custom orodc.dns.hostname label
            # This works for proxy container too (needed for proxy.docker.local and traefik.docker.local)
            custom_hostname=$(docker inspect -f "{{index .Config.Labels \"$LABEL_NAME\"}}" "$container_id" 2>/dev/null || echo "")
            
            if [[ -n "$custom_hostname" ]]; then
                # Support multiple hostnames (comma-separated)
                IFS=',' read -ra HOSTNAMES <<< "$custom_hostname"
                for h in "${HOSTNAMES[@]}"; do
                    h=$(echo "$h" | xargs)  # Trim
                    if [[ -n "$h" ]]; then
                        host_map["$h"]="$container_ip"
                        log "Found (custom): ${h} -> ${container_ip} (${container_name})"
                    fi
                done
            fi
            
            # Method 2: Extract from Traefik router rules
            # Skip Traefik rules for proxy container (to avoid duplicates from custom label)
            if [[ "$container_name" != "proxy" ]]; then
                # Get all traefik.http.routers.*.rule labels
                all_labels=$(docker inspect -f '{{range $k, $v := .Config.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' "$container_id" 2>/dev/null || echo "")
                
                while IFS= read -r label_line; do
                    if [[ "$label_line" =~ traefik\.http\.routers\..*\.rule=(.+)$ ]]; then
                        rule_value="${BASH_REMATCH[1]}"
                        
                        # Extract all Host() entries from the rule
                        while IFS= read -r hostname; do
                            if [[ -n "$hostname" ]]; then
                                host_map["$hostname"]="$container_ip"
                                log "Found (traefik): ${hostname} -> ${container_ip} (${container_name})"
                            fi
                        done < <(extract_hosts_from_rule "$rule_value")
                    fi
                done <<< "$all_labels"
            fi
            
        done < <(docker ps --filter "label=traefik.enable=true" --format "{{.ID}}" 2>/dev/null || echo "")
    fi
    
    # Build entries from deduplicated map
    # Inside proxy container, all hostnames should resolve to 127.0.0.1 (Traefik)
    # so both HTTP and HTTPS work through Traefik
    local entries=""
    for hostname in "${!host_map[@]}"; do
        entries+="127.0.0.1 ${hostname}"$'\n'
    done
    
    # Update /etc/hosts
    local temp_file
    temp_file=$(mktemp)
    
    # Remove old OroDC section
    if grep -q "$MARKER_START" "$HOSTS_FILE" 2>/dev/null; then
        sed "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE" > "$temp_file"
    else
        cat "$HOSTS_FILE" > "$temp_file"
    fi
    
    # Add new OroDC section
    echo "$MARKER_START" >> "$temp_file"
    if [[ -n "$entries" ]]; then
        echo -n "$entries" >> "$temp_file"
    fi
    echo "$MARKER_END" >> "$temp_file"
    
    # Replace hosts file
    cat "$temp_file" > "$HOSTS_FILE"
    rm -f "$temp_file"
    
    local count
    count=$(echo "$entries" | grep -c "." || echo "0")
    log "Updated /etc/hosts: ${count} entries"
}

# Main loop
main() {
    log "Starting DNS sync (container mode)"
    log "Monitoring Docker socket: $DOCKER_SOCK"
    
    # Check if Docker socket is accessible
    if [[ ! -S "$DOCKER_SOCK" ]]; then
        log "ERROR: Docker socket not found at $DOCKER_SOCK"
        exit 1
    fi
    
    # Initial sync
    update_hosts
    
    # Watch Docker events
    log "Watching Docker events..."
    
    if command -v docker >/dev/null 2>&1; then
        # Use docker CLI if available
        docker events --filter 'type=container' --filter 'event=start' \
            --filter 'event=stop' --filter 'event=die' \
            --format '{{.Status}}' 2>/dev/null | while read -r event; do
            log "Event: $event"
            update_hosts
        done
    else
        # Fallback: poll every 10 seconds
        log "Docker CLI not available, polling every 10 seconds"
        while true; do
            sleep 10
            update_hosts
        done
    fi
}

# Trap for cleanup
trap 'log "Shutting down..."; exit 0' SIGTERM SIGINT

main

