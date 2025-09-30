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

# Function to detect ports
detect_ports() {
    echo "🔍 Detecting HTTP port for ${UNIQUE_PROJECT_NAME}..."
    
    # HTTP Port (nginx) - the only one we need for simple test
    HTTP_PORT=$(docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}} {{.Ports}}" | grep nginx | grep -o '[0-9]*->80/tcp' | cut -d- -f1 | head -1)
    
    echo "📋 Detected HTTP port: ${HTTP_PORT:-none}"
    
    if [ -z "$HTTP_PORT" ]; then
        echo "❌ Could not detect HTTP port - this is critical for testing"
        echo "📋 Available containers:"
        docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}} {{.Ports}}"
        return 1
    fi
}

# Function to prepare Goss test file
prepare_goss_file() {
    echo "📝 Preparing Goss test file..."
    
    GOSS_FILE="/tmp/oro-installation-${UNIQUE_PROJECT_NAME}.yaml"
    
    # Copy template and substitute variables
    cp "${GITHUB_WORKSPACE:-$(pwd)}/.github/tests/oro-installation.yaml" "$GOSS_FILE"
    
    # Replace HTTP_PORT with actual detected port
    sed -i "s/HTTP_PORT/${HTTP_PORT}/g" "$GOSS_FILE"
    
    echo "✅ Goss file prepared: $GOSS_FILE"
    echo "🌐 Testing URL: http://localhost:$HTTP_PORT"
}

# Function to wait for HTTP port to be ready
wait_for_http_port() {
    echo "⏳ Waiting for HTTP service on port $HTTP_PORT to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "📡 Attempt $attempt/$max_attempts: Testing HTTP port $HTTP_PORT..."
        
        # Test HTTP connectivity with curl
        if curl -s -f -m 5 "http://localhost:$HTTP_PORT" >/dev/null 2>&1; then
            echo "✅ HTTP service is ready on port $HTTP_PORT!"
            return 0
        fi
        
        # Fallback: test TCP connection
        if timeout 5 bash -c "</dev/tcp/localhost/$HTTP_PORT" >/dev/null 2>&1; then
            echo "✅ HTTP port $HTTP_PORT is accepting connections!"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "❌ HTTP service failed to become ready after $max_attempts attempts"
            return 1
        fi
        
        echo "⏸️  HTTP not ready yet, waiting 10 seconds..."
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
    
    # Step 2: Detect service ports
    detect_ports
    
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
