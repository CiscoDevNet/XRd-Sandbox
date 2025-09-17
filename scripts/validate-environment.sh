#!/usr/bin/env bash

# Script to validate the environment for XRd Sandbox
# This script performs all necessary checks without executing deployment tasks
# Useful for CI/CD pipeline health checks

set -e  # Exit on any error

# Get the script directory to find common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/common_utils.sh"

# Source common utilities
if [[ -f "$COMMON_UTILS" ]]; then
    source "$COMMON_UTILS"
else
    echo "ERROR: Common utilities not found: $COMMON_UTILS"
    exit 1
fi

print_info "XRd Sandbox Environment Validation"
print_info "=================================="

# Initialize environment with all required variables
if ! init_sandbox_environment "XRD_CONTAINER_VERSION" "XRD_CONTAINER_ARCHIVE" "SANDBOX_ROOT" "SANDBOX_IP"; then
    print_error "Environment initialization failed"
    exit 1
fi

print_success "Environment variables loaded successfully"
print_info "XRD_CONTAINER_VERSION: $XRD_CONTAINER_VERSION"
print_info "SANDBOX_ROOT: $SANDBOX_ROOT"
print_info "Container Engine: $CONTAINER_ENGINE_NAME"

# Check if xr-compose tool is available
print_info "Checking for xr-compose tool..."
if command -v xr-compose >/dev/null 2>&1; then
    print_success "xr-compose tool is available"
    print_info "xr-compose version: $(xr-compose --version 2>/dev/null || echo 'version check failed')"
else
    print_error "xr-compose tool not found in PATH"
    print_info "Run 'make clone-xrd-tools' to set up xrd-tools and add scripts to PATH"
    exit 1
fi

# Check if required files exist
print_info "Validating required files..."
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ARCHIVE_PATH="$PROJECT_ROOT/$XRD_CONTAINER_ARCHIVE"


if validate_file_exists "$SANDBOX_ROOT/topologies/segment-routing/docker-compose.xr.yml" "Segment Routing template"; then
    print_success "Segment Routing template found"
else
    print_error "Segment Routing template not found"
    exit 1
fi

# Check container engine functionality
print_info "Testing container engine functionality..."
if $CONTAINER_ENGINE version >/dev/null 2>&1; then
    print_success "Container engine ($CONTAINER_ENGINE_NAME) is working"
else
    print_error "Container engine ($CONTAINER_ENGINE_NAME) is not responding"
    exit 1
fi

# Check if XRd image exists (optional check)
print_info "Checking for XRd container image..."
IMAGE_NAME=$(construct_xrd_image_name "$XRD_CONTAINER_VERSION")
if check_image_exists "$IMAGE_NAME"; then
    print_success "XRd container image is already loaded: $IMAGE_NAME"
else
    print_info "XRd container image not found (this is expected if not yet loaded)"
    print_info "Image will be loaded during setup process"
fi

echo ""
print_success "Environment validation completed successfully!"
print_info "All required components are available for XRd Sandbox deployment"