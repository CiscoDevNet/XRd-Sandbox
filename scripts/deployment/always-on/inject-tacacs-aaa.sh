#!/usr/bin/env bash

set -e  # Exit on any error

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../../lib/common.sh"

# Determine SANDBOX_ROOT - use repository root if SANDBOX_ROOT is not valid
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ ! -d "$SANDBOX_ROOT/topologies/always-on" ]]; then
    if [[ -d "$REPO_ROOT/topologies/always-on" ]]; then
        SANDBOX_ROOT="$REPO_ROOT"
    fi
fi

# Source common utilities if available (for print functions)
if [[ -f "$COMMON_UTILS" ]]; then
    source "$COMMON_UTILS"
else
    # Define basic print functions if common utils not available
    print_info() { echo "[INFO] $*"; }
    print_error() { echo "[ERROR] $*" >&2; }
    print_success() { echo "[SUCCESS] $*"; }
    print_warning() { echo "[WARNING] $*"; }
fi

print_info "Starting TACACS AAA configuration injection for Always-On sandbox..."

# Check if TACACS environment variables are set
missing_vars=()
[[ -z "$TACACS_SERVER_IP" ]] && missing_vars+=("TACACS_SERVER_IP")
[[ -z "$TACACS_SECRET_KEY" ]] && missing_vars+=("TACACS_SECRET_KEY")

if [[ ${#missing_vars[@]} -eq 2 ]]; then
    print_info "TACACS environment variables not set: ${missing_vars[*]}"
    print_info "Skipping TACACS AAA configuration injection - no changes will be made"
    exit 0
elif [[ ${#missing_vars[@]} -eq 1 ]]; then
    print_error "Missing required TACACS environment variable: ${missing_vars[*]}"
    print_error "Both TACACS_SERVER_IP and TACACS_SECRET_KEY are required for TACACS configuration"
    exit 1
fi

print_info "TACACS environment variables detected:"
print_info "  TACACS_SERVER_IP: $TACACS_SERVER_IP"
print_info "  TACACS_SECRET_KEY: [REDACTED]"

# Define paths
AAA_CONFIG_FILE="$SCRIPT_DIR/aaa-config.cfg"
TOPOLOGY_DIR="$SANDBOX_ROOT/topologies/always-on"

# Validate AAA config exists
if [[ ! -f "$AAA_CONFIG_FILE" ]]; then
    print_error "AAA config file not found: $AAA_CONFIG_FILE"
    exit 1
fi

# Validate topology directory exists
if [[ ! -d "$TOPOLOGY_DIR" ]]; then
    print_error "Topology directory not found: $TOPOLOGY_DIR"
    exit 1
fi

# Function to inject configuration into startup file
inject_config_to_file() {
    local startup_file="$1"
    local aaa_config="$2"
    local temp_file="${startup_file}.tmp"
    
    if [[ ! -f "$startup_file" ]]; then
        print_error "Startup file not found: $startup_file"
        return 1
    fi
    
    # Create temporary file with injected config at the beginning
    {
        echo "$aaa_config"
        cat "$startup_file"
    } > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$startup_file"
    
    print_success "AAA configuration injected into $(basename "$startup_file")"
}

# Read the AAA configuration content
AAA_CONFIG=$(cat "$AAA_CONFIG_FILE")

# Find all startup.cfg files in the topology directory
print_info "Searching for startup configuration files in $TOPOLOGY_DIR..."

startup_files=("$TOPOLOGY_DIR"/xrd-*-startup.cfg)

if [[ ${#startup_files[@]} -eq 0 ]]; then
    print_error "No startup configuration files found in $TOPOLOGY_DIR"
    exit 1
fi

# Inject configuration into each startup file
for startup_file in "${startup_files[@]}"; do
    if [[ -f "$startup_file" ]]; then
        print_info "Processing $(basename "$startup_file")..."
        inject_config_to_file "$startup_file" "$AAA_CONFIG"
    fi
done

print_success "TACACS AAA configuration injection completed successfully!"
print_info "Note: AAA configuration has been injected at the beginning of each startup file"
print_info "The AAA configuration will work in conjunction with TACACS server at $TACACS_SERVER_IP"
