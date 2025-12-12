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

print_info "Creating deployment configuration files..."

# Initialize sandbox environment
if ! init_sandbox_environment SANDBOX_IP; then
    exit 1
fi

# Define topology directory
TOPOLOGY_DIR="$SANDBOX_ROOT/topologies/always-on"

# Create deployment config files from base configs
for i in 1 2 3; do
    BASE_CFG="$TOPOLOGY_DIR/xrd-${i}-startup.cfg"
    DEPLOY_CFG="$TOPOLOGY_DIR/xrd-${i}-startup.deploy.cfg"
    
    if [[ -f "$BASE_CFG" ]]; then
        if ! run_command "Copying $BASE_CFG to $DEPLOY_CFG..." \
            cp "$BASE_CFG" "$DEPLOY_CFG"; then
            exit 1
        fi
    else
        print_error "Base config file not found: $BASE_CFG"
        exit 1
    fi
done

print_success "Deployment configuration files created"
