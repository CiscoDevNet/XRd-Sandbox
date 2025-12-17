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

print_info "Verifying Always-On topology deployment..."

# Initialize sandbox environment
if ! init_sandbox_environment SANDBOX_IP; then
    exit 1
fi

# Define file path
OUTPUT_FILE="$SANDBOX_ROOT/topologies/always-on/docker-compose.yml"

# Give containers time to fully start
sleep 5

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
