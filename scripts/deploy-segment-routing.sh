#!/bin/bash

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

print_info "Starting Segment Routing sandbox deployment..."

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
INPUT_FILE="$SANDBOX_ROOT/topologies/segment-routing/docker-compose.xr.yml"
OUTPUT_FILE="$SANDBOX_ROOT/topologies/segment-routing/docker-compose.yml"

# Validate input file exists
if ! validate_file_exists "$INPUT_FILE" "Input file"; then
    exit 1
fi

# Step 1: Generate docker-compose.yml using xr-compose
if ! run_command "Generating docker-compose.yml using xr-compose..." \
    xr-compose \
    --input-file "$INPUT_FILE" \
    --output-file "$OUTPUT_FILE" \
    --image "$IMAGE_NAME"; then
    exit 1
fi
print_success "Successfully generated $OUTPUT_FILE"

# Step 2: Modify the generated file to replace interface names
if ! run_command "Updating interface names in docker-compose.yml..." \
    sed -i.bak 's/linux:xr-120/linux:eth0/g' "$OUTPUT_FILE"; then
    exit 1
fi
print_success "Interface names updated successfully"

# Step 3: Detect and update macvlan parent interface
DETECTED_INTERFACE=$(detect_network_interface "$SANDBOX_IP")
if [[ $? -eq 0 ]] && [[ -n "$DETECTED_INTERFACE" ]]; then
    if ! run_command "Updating macvlan parent interface to $DETECTED_INTERFACE..." \
        update_macvlan_parent_interface "$OUTPUT_FILE" "$DETECTED_INTERFACE" "no-backup"; then
        print_warning "Failed to update macvlan parent interface, continuing with existing configuration"
    fi
else
    print_warning "Could not detect network interface for $SANDBOX_IP, using existing configuration"
fi

# Step 4: Deploy the topology
if ! run_command "Deploying the Segment Routing topology..." \
    $CONTAINER_ENGINE compose --file "$OUTPUT_FILE" up --detach; then
    exit 1
fi

# Step 5: Verify deployment
verify_compose_deployment "$OUTPUT_FILE"
