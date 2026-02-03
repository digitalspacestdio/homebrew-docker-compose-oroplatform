#!/bin/bash
set -e

# OroDC Installation Verification using Goss
# This script installs Goss and runs comprehensive tests

# Check required environment variables
if [ -z "$UNIQUE_PROJECT_NAME" ]; then
    echo "❌ Error: UNIQUE_PROJECT_NAME environment variable not set"
    exit 1
fi

echo "🧪 Setting up Goss testing for OroDC installation..."

# Function to install Goss
install_goss() {
    if command -v goss >/dev/null 2>&1; then
        echo "✅ Goss already installed: $(goss --version)"
        return
    fi
    
    echo "📦 Installing Goss..."
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            GOSS_ARCH="amd64"
            ;;
        aarch64|arm64)
            GOSS_ARCH="arm64"
            ;;
        *)
            echo "❌ Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    echo "🔍 Detected architecture: $ARCH → using goss-linux-$GOSS_ARCH"
    
    GOSS_VERSION="0.4.7"
    curl -fsSL https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-linux-${GOSS_ARCH} -o /tmp/goss
    chmod +x /tmp/goss
    sudo mv /tmp/goss /usr/local/bin/goss
    echo "✅ Goss installed: $(goss --version)"
}

# Function to detect nginx container and connect to its network
detect_nginx_container() {
    echo "🔍 Detecting nginx container for ${UNIQUE_PROJECT_NAME}..."
    
    # Get nginx container name
    NGINX_CONTAINER=$(docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}}" | grep nginx | head -1)
    
    if [ -z "$NGINX_CONTAINER" ]; then
        echo "❌ Could not find nginx container"
        echo "📋 Available containers:"
        docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}}"
        return 1
    fi
    
    echo "📋 Found nginx container: $NGINX_CONTAINER"
    
    # Get OroDC network name
    DC_ORO_NETWORK=$(docker inspect "$NGINX_CONTAINER" --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}} {{end}}' | awk '{print $1}')
    
    if [ -z "$DC_ORO_NETWORK" ]; then
        echo "❌ Could not detect OroDC network"
        return 1
    fi
    
    echo "📋 Found OroDC network: $DC_ORO_NETWORK"
    
    # Connect current container to OroDC network
    echo "🔗 Connecting to OroDC network..."
    CURRENT_CONTAINER=$(hostname)
    docker network connect "$DC_ORO_NETWORK" "$CURRENT_CONTAINER" 2>/dev/null || {
        echo "⚠️  Already connected to network or connection failed, continuing..."
    }
    
    # We'll test nginx directly on port 80
    NGINX_HOST="$NGINX_CONTAINER"
    HTTP_PORT="80"
    
    echo "✅ Will test nginx directly: $NGINX_HOST:$HTTP_PORT"
}

# Function to prepare Goss test file
prepare_goss_file() {
    echo "📝 Preparing Goss test file..."
    
    GOSS_FILE="/tmp/oro-installation-${UNIQUE_PROJECT_NAME}.yaml"
    
    # Copy template and substitute variables
    cp "${GITHUB_WORKSPACE:-$(pwd)}/.github/tests/oro-installation.yaml" "$GOSS_FILE"
    
    # Replace placeholder with nginx container name and port
    sed -i "s/localhost:HTTP_PORT/${NGINX_HOST}:${HTTP_PORT}/g" "$GOSS_FILE"
    
    echo "✅ Goss file prepared: $GOSS_FILE"
    echo "🌐 Testing URL: http://$NGINX_HOST:$HTTP_PORT"
}

# Function to wait for nginx container to be ready
wait_for_http_port() {
    echo "⏳ Waiting for nginx container $NGINX_HOST:$HTTP_PORT to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "📡 Attempt $attempt/$max_attempts: Testing nginx at $NGINX_HOST:$HTTP_PORT..."
        
        # Test HTTP connectivity with curl
        if curl -s -f -m 5 "http://$NGINX_HOST:$HTTP_PORT" >/dev/null 2>&1; then
            echo "✅ Nginx container is ready at $NGINX_HOST:$HTTP_PORT!"
            return 0
        fi
        
        # Fallback: test TCP connection to nginx container
        if timeout 5 bash -c "</dev/tcp/$NGINX_HOST/$HTTP_PORT" >/dev/null 2>&1; then
            echo "✅ Nginx port $NGINX_HOST:$HTTP_PORT is accepting connections!"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ Nginx container failed to become ready after $max_attempts attempts"
            return 1
        fi
        
        echo "⏸️  Nginx not ready yet, waiting 10 seconds..."
        sleep 10
        attempt=$((attempt + 1))
    done
}

# Function to run Goss tests
run_goss_tests() {
    echo "🚀 Running Goss tests..."
    
    # Set working directory to project directory if provided
    if [ -n "$PROJECT_DIR" ]; then
        cd "$PROJECT_DIR"
    fi
    
    # Run Goss with custom test file
    if goss -g "$GOSS_FILE" validate --format junit > "/tmp/goss-results-${UNIQUE_PROJECT_NAME}.xml"; then
        echo "✅ All Goss tests PASSED!"
        
        # Also run with documentation output for console
        echo ""
        echo "📊 Detailed test results:"
        goss -g "$GOSS_FILE" validate --format documentation || true
        
        return 0
    else
        echo "❌ Some Goss tests FAILED!"
        
        # Show detailed results even on failure
        echo ""
        echo "📊 Detailed test results:"
        goss -g "$GOSS_FILE" validate --format documentation || true
        
        return 1
    fi
}

# Main execution
main() {
    echo "🏁 Starting OroDC installation verification with Goss"
    echo "Project: $UNIQUE_PROJECT_NAME"
    echo ""
    
    # Step 1: Install Goss
    install_goss
    
    # Step 2: Detect nginx container and connect to network
    detect_nginx_container
    
    # Step 3: Prepare Goss test file  
    prepare_goss_file
    
    # Step 4: Wait for HTTP service to be ready
    wait_for_http_port
    
    # Step 5: Run tests
    run_goss_tests
    
    echo ""
    echo "🎉 OroDC installation verification completed successfully!"
}

# Execute main function
main "$@"
