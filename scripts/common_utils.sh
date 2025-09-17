#!/bin/bash

# Common utilities for XRd Sandbox scripts
# This script should be sourced by other scripts to provide common functionality

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

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

# Function to get the sandbox root directory
get_sandbox_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    echo "$(dirname "$script_dir")"
}

# Function to load environment variables from sandbox_env_vars.sh
load_sandbox_env() {
    local sandbox_root="${1:-$(get_sandbox_root)}"
    local env_vars_file="$sandbox_root/sandbox_env_vars.sh"
    
    # Check if critical environment variables are already set
    if [[ -n "$XRD_CONTAINER_VERSION" ]] && [[ -n "$XRD_CONTAINER_ARCHIVE" ]]; then
        print_info "Using existing environment variables (XRD_CONTAINER_VERSION=$XRD_CONTAINER_VERSION)"
        return 0
    fi
    
    if [[ -f "$env_vars_file" ]]; then
        print_info "Loading environment variables from $env_vars_file"
        source "$env_vars_file"
        return 0
    else
        print_error "Environment variables file not found: $env_vars_file"
        return 1
    fi
}

# Function to validate required environment variables
validate_env_vars() {
    local missing_vars=()
    
    for var in "$@"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    return 0
}

# Function to detect and validate container engine (docker or podman)
detect_container_engine() {
    local container_engine
    container_engine=$(which docker 2>/dev/null || which podman 2>/dev/null)
    
    if [[ -z "$container_engine" ]]; then
        print_error "Neither Docker nor Podman is installed or in PATH"
        return 1
    fi
    
    local engine_name
    engine_name=$(basename "$container_engine")
    print_info "Using container engine: $engine_name"
    
    # Export variables for use in calling script
    export CONTAINER_ENGINE="$container_engine"
    export CONTAINER_ENGINE_NAME="$engine_name"
    
    return 0
}

# Function to check if a Docker/Podman image exists
check_image_exists() {
    local image_name="$1"
    
    if [[ -z "$image_name" ]]; then
        print_error "Image name is required"
        return 1
    fi
    
    if [[ -z "$CONTAINER_ENGINE" ]]; then
        print_error "Container engine not detected. Run detect_container_engine first."
        return 1
    fi
    
    print_info "Checking if image $image_name exists..."
    
    if ! $CONTAINER_ENGINE image inspect "$image_name" >/dev/null 2>&1; then
        print_error "Image $image_name not found!"
        print_info "Please ensure the image exists by running: $CONTAINER_ENGINE_NAME pull $image_name"
        return 1
    fi
    
    print_success "Image $image_name found"
    return 0
}

# Function to validate file exists
validate_file_exists() {
    local file_path="$1"
    local description="${2:-File}"
    
    if [[ -z "$file_path" ]]; then
        print_error "File path is required"
        return 1
    fi
    
    if [[ ! -f "$file_path" ]]; then
        print_error "$description not found: $file_path"
        return 1
    fi
    
    return 0
}

# Function to construct image name from base and tag
construct_image_name() {
    local base_image="$1"
    local tag_image="$2"
    
    if [[ -z "$base_image" ]] || [[ -z "$tag_image" ]]; then
        print_error "Both base_image and tag_image are required"
        return 1
    fi
    
    echo "${base_image}:${tag_image}"
}

# Function to verify docker compose deployment
verify_compose_deployment() {
    local compose_file="$1"
    local sleep_time="${2:-3}"
    
    if [[ -z "$compose_file" ]]; then
        print_error "Docker compose file is required"
        return 1
    fi
    
    if [[ -z "$CONTAINER_ENGINE" ]]; then
        print_error "Container engine not detected. Run detect_container_engine first."
        return 1
    fi
    
    print_info "Verifying deployment..."
    sleep "$sleep_time"  # Give containers a moment to start
    
    # Check if containers are running
    local running_containers
    local total_services
    
    running_containers=$($CONTAINER_ENGINE compose --file "$compose_file" ps --services --filter "status=running" 2>/dev/null | wc -l)
    total_services=$($CONTAINER_ENGINE compose --file "$compose_file" config --services 2>/dev/null | wc -l)
    
    if [[ $running_containers -eq $total_services ]] && [[ $running_containers -gt 0 ]]; then
        print_success "Deployment successful! All $total_services containers are running."
        print_info "You can check the status with: $CONTAINER_ENGINE_NAME compose --file $compose_file ps"
        print_info "To view logs: $CONTAINER_ENGINE_NAME compose --file $compose_file logs --follow"
        return 0
    else
        print_warning "Deployment completed but not all containers may be running ($running_containers/$total_services)"
        print_info "Check container status with: $CONTAINER_ENGINE_NAME compose --file $compose_file ps"
        return 1
    fi
}

# Function to run a command with error checking and logging
run_command() {
    local description="$1"
    shift
    local command=("$@")
    
    print_info "$description"
    
    if ! "${command[@]}"; then
        print_error "Failed: $description"
        return 1
    fi
    
    return 0
}

# Function to initialize common setup (load env, detect container engine, etc.)
init_sandbox_environment() {
    local required_vars=("$@")
    
    # Load environment variables
    if ! load_sandbox_env; then
        return 1
    fi
    
    # Validate required environment variables
    if [[ ${#required_vars[@]} -gt 0 ]]; then
        if ! validate_env_vars "${required_vars[@]}"; then
            return 1
        fi
    fi
    
    # Detect container engine
    if ! detect_container_engine; then
        return 1
    fi
    
    return 0
}

# Export all functions for use in other scripts
export -f print_info print_success print_warning print_error
export -f get_sandbox_root load_sandbox_env validate_env_vars
export -f detect_container_engine check_image_exists validate_file_exists
export -f construct_image_name verify_compose_deployment run_command
export -f init_sandbox_environment