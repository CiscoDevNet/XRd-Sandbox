#!/usr/bin/env bash

set -e  # Exit on any error

# Get the script directory to find common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../lib/common.sh"

# Source common utilities
if [[ -f "$COMMON_UTILS" ]]; then
    source "$COMMON_UTILS"
else
    echo "ERROR: Common utilities not found: $COMMON_UTILS"
    exit 1
fi

print_info "Starting Always-On sandbox deployment..."

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
    sed -i.bak 's/linux:xr-30/linux:eth0/g' "$OUTPUT_FILE"; then
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
if ! run_command "Deploying the Always-On topology..." \
    $CONTAINER_ENGINE compose --file "$OUTPUT_FILE" up --detach; then
    exit 1
fi

# Step 5: Verify deployment with specific container checks
print_info "Verifying Always-On topology deployment..."
sleep 5  # Give containers time to fully start

# Check that all three expected containers are running
EXPECTED_CONTAINERS=("xrd-1" "xrd-2" "xrd-3")
RUNNING_CONTAINERS=()
FAILED_CONTAINERS=()

for container in "${EXPECTED_CONTAINERS[@]}"; do
    if $CONTAINER_ENGINE inspect "$container" >/dev/null 2>&1; then
        status=$($CONTAINER_ENGINE inspect --format '{{.State.Status}}' "$container" 2>/dev/null)
        if [[ "$status" == "running" ]]; then
            RUNNING_CONTAINERS+=("$container")
            print_success "Container $container is running"
        else
            FAILED_CONTAINERS+=("$container")
            print_error "Container $container exists but is not running (status: $status)"
        fi
    else
        FAILED_CONTAINERS+=("$container")
        print_error "Container $container does not exist"
    fi
done

# Report results
if [[ ${#RUNNING_CONTAINERS[@]} -eq 3 ]]; then
    print_success "Always-On topology deployment successful! All 3 containers are running:"
    for container in "${RUNNING_CONTAINERS[@]}"; do
        print_info "  ✓ $container"
    done
    print_info ""
    print_info "Management IP addresses:"
    print_info "  xrd-1: 10.10.20.101"
    print_info "  xrd-2: 10.10.20.102"
    print_info "  xrd-3: 10.10.20.103"
    print_info ""
    print_info "Credentials: cisco/C1sco12345"
    print_info ""
    print_info "Useful commands:"
    print_info "  Check status: $CONTAINER_ENGINE_NAME compose --file $OUTPUT_FILE ps"
    print_info "  View logs:    $CONTAINER_ENGINE_NAME compose --file $OUTPUT_FILE logs --follow"
    print_info "  Connect:      $CONTAINER_ENGINE_NAME exec -it <container-name> xr"
else
    print_error "Deployment verification failed! Running: ${#RUNNING_CONTAINERS[@]}/3 containers"
    if [[ ${#FAILED_CONTAINERS[@]} -gt 0 ]]; then
        print_error "Failed containers: ${FAILED_CONTAINERS[*]}"
        print_info "Check logs with: $CONTAINER_ENGINE_NAME compose --file $OUTPUT_FILE logs"
    fi
    exit 1
fi