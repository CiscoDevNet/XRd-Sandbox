#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the script directory to find the sandbox_env_vars.sh file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_VARS_FILE="$SANDBOX_ROOT/sandbox_env_vars.sh"

print_info "Starting Segment Routing sandbox deployment..."

# Source environment variables
if [[ -f "$ENV_VARS_FILE" ]]; then
    print_info "Loading environment variables from $ENV_VARS_FILE"
    source "$ENV_VARS_FILE"
else
    print_error "Environment variables file not found: $ENV_VARS_FILE"
    exit 1
fi

# Validate required variables
if [[ -z "$BASE_IMAGE" ]] || [[ -z "$TAG_IMAGE" ]]; then
    print_error "BASE_IMAGE and TAG_IMAGE must be defined in $ENV_VARS_FILE"
    exit 1
fi

IMAGE_NAME="${BASE_IMAGE}:${TAG_IMAGE}"
print_info "Using Docker image: $IMAGE_NAME"

# Detect container engine (docker or podman)
CONTAINER_ENGINE=$(which docker 2>/dev/null || which podman 2>/dev/null)
if [[ -z "$CONTAINER_ENGINE" ]]; then
    print_error "Neither Docker nor Podman is installed or in PATH"
    exit 1
fi

CONTAINER_ENGINE_NAME=$(basename "$CONTAINER_ENGINE")
print_info "Using container engine: $CONTAINER_ENGINE_NAME"

# Check if the Docker image exists
print_info "Checking if image $IMAGE_NAME exists..."
if ! $CONTAINER_ENGINE image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    print_error "Docker image $IMAGE_NAME not found!"
    print_info "Please ensure the image exists by running: $CONTAINER_ENGINE_NAME pull $IMAGE_NAME"
    exit 1
fi
print_success "Image $IMAGE_NAME found"

# Define file paths
INPUT_FILE="$HOME/XRd-Sandbox/topologies/segment-routing/docker-compose.xr.yml"
OUTPUT_FILE="$HOME/XRd-Sandbox/topologies/segment-routing/docker-compose.yml"

# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    print_error "Input file not found: $INPUT_FILE"
    exit 1
fi

# Step 1: Generate docker-compose.yml using xr-compose
print_info "Generating docker-compose.yml using xr-compose..."
if ! xr-compose \
  --input-file "$INPUT_FILE" \
  --output-file "$OUTPUT_FILE" \
  --image "$IMAGE_NAME"; then
    print_error "Failed to generate docker-compose.yml"
    exit 1
fi
print_success "Successfully generated $OUTPUT_FILE"

# Step 2: Modify the generated file to replace interface names
print_info "Updating interface names in docker-compose.yml..."
if ! sed -i.bak 's/linux:xr-120/linux:eth0/g' "$OUTPUT_FILE"; then
    print_error "Failed to update interface names"
    exit 1
fi
print_success "Interface names updated successfully"

# Step 3: Deploy the topology
print_info "Deploying the Segment Routing topology..."
if ! $CONTAINER_ENGINE compose --file "$OUTPUT_FILE" up --detach; then
    print_error "Failed to deploy the topology"
    exit 1
fi

# Step 4: Verify deployment
print_info "Verifying deployment..."
sleep 3  # Give containers a moment to start

# Check if containers are running
RUNNING_CONTAINERS=$($CONTAINER_ENGINE compose --file "$OUTPUT_FILE" ps --services --filter "status=running" | wc -l)
TOTAL_SERVICES=$($CONTAINER_ENGINE compose --file "$OUTPUT_FILE" config --services | wc -l)

if [[ $RUNNING_CONTAINERS -eq $TOTAL_SERVICES ]] && [[ $RUNNING_CONTAINERS -gt 0 ]]; then
    print_success "Deployment successful! All $TOTAL_SERVICES containers are running."
    print_info "You can check the status with: $CONTAINER_ENGINE_NAME compose --file $OUTPUT_FILE ps"
    print_info "To view logs: $CONTAINER_ENGINE_NAME compose --file $OUTPUT_FILE logs --follow"
else
    print_warning "Deployment completed but not all containers may be running ($RUNNING_CONTAINERS/$TOTAL_SERVICES)"
    print_info "Check container status with: $CONTAINER_ENGINE_NAME compose --file $OUTPUT_FILE ps"
fi
