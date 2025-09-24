#!/usr/bin/env bash

# Example script showing how to use common utilities
# This can serve as a template for creating new deployment scripts

set -e  # Exit on any error

# Get the script directory to find common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
<parameter name="COMMON_UTILS">="$SCRIPT_DIR/../lib/common.sh"

# Source common utilities
if [[ -f "$COMMON_UTILS" ]]; then
    source "$COMMON_UTILS"
else
    echo "ERROR: Common utilities not found: $COMMON_UTILS"
    exit 1
fi

print_info "Example script demonstrating common utilities usage"

# Example 1: Initialize environment
print_info "=== Example 1: Environment Initialization ==="
if init_sandbox_environment; then
    print_success "Environment initialized successfully"
    print_info "XRD_CONTAINER_VERSION: $XRD_CONTAINER_VERSION"
    print_info "Container Engine: $CONTAINER_ENGINE_NAME"
else
    print_error "Failed to initialize environment"
    exit 1
fi

# Example 2: Construct and check XRd image
print_info "=== Example 2: XRd Image Operations ==="
IMAGE_NAME=$(construct_xrd_image_name "$XRD_CONTAINER_VERSION")
print_info "Constructed XRd image name: $IMAGE_NAME"

# Note: Image check will likely fail in test environment, so we'll catch it
if check_image_exists "$IMAGE_NAME"; then
    print_success "Image exists and is ready to use"
else
    print_warning "Image check failed (this is expected in test environment)"
fi

# Example 3: File validation
print_info "=== Example 3: File Validation ==="
if validate_file_exists "$SANDBOX_ROOT/sandbox_env_vars.sh" "Environment variables file"; then
    print_success "Environment file validation passed"
fi

# Example 4: Running commands with logging
print_info "=== Example 4: Command Execution ==="
if run_command "Testing echo command" echo "Hello from common utilities!"; then
    print_success "Command execution example completed"
fi

print_success "All examples completed successfully!"
print_info "You can now use these utilities in your own deployment scripts"