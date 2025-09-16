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

# Initialize sandbox environment with required variables
if ! init_sandbox_environment "BASE_IMAGE" "TAG_IMAGE"; then
    exit 1
fi

# Construct image name from environment variables
IMAGE_NAME=$(construct_image_name "$BASE_IMAGE" "$TAG_IMAGE")
print_info "Using Docker image: $IMAGE_NAME"

# Check if the Docker image exists
if ! check_image_exists "$IMAGE_NAME"; then
    exit 1
fi

# Define file paths
INPUT_FILE="$HOME/XRd-Sandbox/topologies/segment-routing/docker-compose.xr.yml"
OUTPUT_FILE="$HOME/XRd-Sandbox/topologies/segment-routing/docker-compose.yml"

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

# Step 3: Deploy the topology
if ! run_command "Deploying the Segment Routing topology..." \
    $CONTAINER_ENGINE compose --file "$OUTPUT_FILE" up --detach; then
    exit 1
fi

# Step 4: Verify deployment
verify_compose_deployment "$OUTPUT_FILE"
