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

print_info "Generating docker-compose.yml for Always-On topology..."

# Initialize sandbox environment
if ! init_sandbox_environment SANDBOX_IP; then
    exit 1
fi

# Construct XRd image name using standard format
IMAGE_NAME=$(construct_xrd_image_name "$XRD_CONTAINER_VERSION")
print_info "Using Docker image: $IMAGE_NAME"

# Check if the Docker image exists
if ! check_image_exists "$IMAGE_NAME"; then
    exit 1
fi

# Define file paths
INPUT_FILE="$SANDBOX_ROOT/topologies/always-on/docker-compose.xr.yml"
OUTPUT_FILE="$SANDBOX_ROOT/topologies/always-on/docker-compose.yml"

# Validate input file exists
if ! validate_file_exists "$INPUT_FILE" "Input file"; then
    exit 1
fi

# Generate docker-compose.yml using xr-compose
if ! run_command "Generating docker-compose.yml using xr-compose..." \
    xr-compose \
    --input-file "$INPUT_FILE" \
    --output-file "$OUTPUT_FILE" \
    --image "$IMAGE_NAME"; then
    exit 1
fi
print_success "Successfully generated $OUTPUT_FILE"

# Modify the generated file to replace interface names
if ! run_command "Updating interface names in docker-compose.yml..." \
    sed -i.bak 's/linux:xr-30/linux:eth0/g' "$OUTPUT_FILE"; then
    exit 1
fi
print_success "Interface names updated successfully"

# Detect and update macvlan parent interface
DETECTED_INTERFACE=$(detect_network_interface "$SANDBOX_IP")
if [[ $? -eq 0 ]] && [[ -n "$DETECTED_INTERFACE" ]]; then
    if ! run_command "Updating macvlan parent interface to $DETECTED_INTERFACE..." \
        update_macvlan_parent_interface "$OUTPUT_FILE" "$DETECTED_INTERFACE" "no-backup"; then
        print_warning "Failed to update macvlan parent interface, continuing with existing configuration"
    fi
else
    print_warning "Could not detect network interface for $SANDBOX_IP, using existing configuration"
fi

print_success "docker-compose.yml is ready for deployment"
