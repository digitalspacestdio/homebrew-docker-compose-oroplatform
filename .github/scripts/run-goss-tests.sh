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
    GOSS_VERSION="0.4.7"
    curl -fsSL https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64 -o /tmp/goss
    chmod +x /tmp/goss
    sudo mv /tmp/goss /usr/local/bin/goss
    echo "✅ Goss installed: $(goss --version)"
}

# Function to detect ports
detect_ports() {
    echo "🔍 Detecting service ports for ${UNIQUE_PROJECT_NAME}..."
    
    # HTTP Port (nginx)
    HTTP_PORT=$(docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}} {{.Ports}}" | grep nginx | grep -o '[0-9]*->80/tcp' | cut -d- -f1 | head -1)
    
    # PostgreSQL Port
    PG_PORT=$(docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}} {{.Ports}}" | grep database | grep -o '[0-9]*->5432/tcp' | cut -d- -f1 | head -1)
    
    # Elasticsearch Port  
    ES_PORT=$(docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}} {{.Ports}}" | grep search | grep -o '[0-9]*->9200/tcp' | cut -d- -f1 | head -1)
    
    # RabbitMQ Port
    RABBITMQ_PORT=$(docker ps --filter "name=${UNIQUE_PROJECT_NAME}" --format "{{.Names}} {{.Ports}}" | grep mq | grep -o '[0-9]*->15672/tcp' | cut -d- -f1 | head -1)
    
    echo "📋 Detected ports:"
    echo "  HTTP: ${HTTP_PORT:-none}"
    echo "  PostgreSQL: ${PG_PORT:-none}"  
    echo "  Elasticsearch: ${ES_PORT:-none}"
    echo "  RabbitMQ: ${RABBITMQ_PORT:-none}"
    
    if [ -z "$HTTP_PORT" ]; then
        echo "❌ Could not detect HTTP port - this is critical for testing"
        return 1
    fi
}

# Function to prepare Goss test file
prepare_goss_file() {
    echo "📝 Preparing Goss test file..."
    
    GOSS_FILE="/tmp/oro-installation-${UNIQUE_PROJECT_NAME}.yaml"
    
    # Copy template and substitute variables
    cp "${GITHUB_WORKSPACE:-$(pwd)}/.github/tests/oro-installation.yaml" "$GOSS_FILE"
    
    # Replace placeholders with actual values
    sed -i "s/HTTP_PORT/${HTTP_PORT}/g" "$GOSS_FILE"
    sed -i "s/PG_PORT/${PG_PORT}/g" "$GOSS_FILE" 
    sed -i "s/ES_PORT/${ES_PORT}/g" "$GOSS_FILE"
    sed -i "s/RABBITMQ_PORT/${RABBITMQ_PORT}/g" "$GOSS_FILE"
    sed -i "s/PROJECT_NAME/${UNIQUE_PROJECT_NAME}/g" "$GOSS_FILE"
    
    echo "✅ Goss file prepared: $GOSS_FILE"
}

# Function to run Goss tests
run_goss_tests() {
    echo "🚀 Running Goss tests..."
    
    # Set working directory to project directory if provided
    if [ -n "$PROJECT_DIR" ]; then
        cd "$PROJECT_DIR"
    fi
    
    # Run Goss with custom test file
    if goss --gossfile "$GOSS_FILE" validate --format junit > "/tmp/goss-results-${UNIQUE_PROJECT_NAME}.xml"; then
        echo "✅ All Goss tests PASSED!"
        
        # Also run with pretty output for console
        echo ""
        echo "📊 Detailed test results:"
        goss --gossfile "$GOSS_FILE" validate --format pretty || true
        
        return 0
    else
        echo "❌ Some Goss tests FAILED!"
        
        # Show detailed results even on failure
        echo ""
        echo "📊 Detailed test results:"
        goss --gossfile "$GOSS_FILE" validate --format pretty || true
        
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
    
    # Step 4: Run tests
    run_goss_tests
    
    echo ""
    echo "🎉 OroDC installation verification completed successfully!"
}

# Execute main function
main "$@"
