#!/usr/bin/env bash

set -euo pipefail  # Exit on error, unset vars, and pipeline failures

# Get the script directory to find common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../../lib/common.sh"

# Source common utilities
if [[ -f "$COMMON_UTILS" ]]; then
    source "$COMMON_UTILS"
else
    echo "ERROR: Common utilities not found: $COMMON_UTILS"
    exit 1
fi

print_info "Starting Always-On topology containers..."

# Initialize sandbox environment
if ! init_sandbox_environment SANDBOX_IP; then
    exit 1
fi

# Define file path
OUTPUT_FILE="$SANDBOX_ROOT/topologies/always-on/docker-compose.yml"

# Validate docker-compose.yml exists
if ! validate_file_exists "$OUTPUT_FILE" "docker-compose.yml"; then
    print_error "docker-compose.yml not found. Run 'make generate-compose-always-on' first."
    exit 1
fi

# Deploy the topology
if ! run_command "Deploying the Always-On topology..." \
    $CONTAINER_ENGINE compose --file "$OUTPUT_FILE" up --detach; then
    exit 1
fi

print_success "Always-On topology containers started"
print_info "Run 'make verify-always-on' to verify deployment"
