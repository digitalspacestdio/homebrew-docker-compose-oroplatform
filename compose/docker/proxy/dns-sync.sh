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

# Update /etc/hosts with container DNS names
update_hosts() {
    log "Updating /etc/hosts inside container..."
    
    # Get all running containers with the label
    local entries=""
    
    # Query Docker API via Unix socket using curl
    local containers
    containers=$(curl -s --unix-socket "$DOCKER_SOCK" \
        "http://localhost/containers/json?filters=%7B%22label%22%3A%5B%22${LABEL_NAME}%22%5D%7D" || echo "[]")
    
    # Parse JSON and extract hostnames and container names
    echo "$containers" | grep -o '"Labels":{[^}]*}' | while read -r labels_block; do
        # Extract hostname from label
        hostname=$(echo "$labels_block" | grep -o "\"${LABEL_NAME}\":\"[^\"]*\"" | cut -d'"' -f4 || echo "")
        
        if [[ -n "$hostname" ]]; then
            # Get container name from same container
            container_name=$(echo "$containers" | grep -B20 "$hostname" | grep -o '"Name":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/^\///' || echo "")
            
            if [[ -n "$container_name" ]]; then
                # Map hostname to Docker container DNS name
                entries+="${container_name} ${hostname}"$'\n'
                log "Mapping: ${hostname} -> ${container_name}"
            fi
        fi
    done
    
    # Alternative simpler approach using docker CLI if available
    if command -v docker >/dev/null 2>&1; then
        while IFS= read -r container_id; do
            if [[ -z "$container_id" ]]; then
                continue
            fi
            
            # Get hostname and container name
            hostname=$(docker inspect -f "{{index .Config.Labels \"$LABEL_NAME\"}}" "$container_id" 2>/dev/null || echo "")
            container_name=$(docker inspect -f "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///' || echo "")
            
            if [[ -n "$hostname" ]] && [[ -n "$container_name" ]]; then
                # Support multiple hostnames (comma-separated)
                IFS=',' read -ra HOSTNAMES <<< "$hostname"
                for h in "${HOSTNAMES[@]}"; do
                    h=$(echo "$h" | xargs)  # Trim
                    if [[ -n "$h" ]]; then
                        entries+="${container_name} ${h}"$'\n'
                        log "Mapping: ${h} -> ${container_name}"
                    fi
                done
            fi
        done < <(docker ps --filter "label=$LABEL_NAME" --format "{{.ID}}" 2>/dev/null || echo "")
    fi
    
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

