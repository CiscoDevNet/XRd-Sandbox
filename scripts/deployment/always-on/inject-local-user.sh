#!/usr/bin/env bash

set -eo pipefail  # Exit on error, catch pipeline failures

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
fi

print_info "Starting local user configuration injection for Always-On sandbox..."

# Define paths
FALLBACK_CONFIG_FILE="$SCRIPT_DIR/fallback_local_user.cfg"
TOPOLOGY_DIR="$SANDBOX_ROOT/topologies/always-on"

# Validate fallback config exists
if [[ ! -f "$FALLBACK_CONFIG_FILE" ]]; then
    print_error "Fallback local user config file not found: $FALLBACK_CONFIG_FILE"
    exit 1
fi

# Validate topology directory exists
if [[ ! -d "$TOPOLOGY_DIR" ]]; then
    print_error "Topology directory not found: $TOPOLOGY_DIR"
    exit 1
fi

# Function to generate local user configuration
generate_local_user_config() {
    local config=""
    
    # Check if environment variables are set
    if [[ -n "$FALLBACK_LOCAL_USERNAME" && -n "$FALLBACK_LOCAL_PASSWORD" ]]; then
        print_info "Using fallback local user credentials from environment variables" >&2
        
        # Generate password hash using Python's crypt module for SHA-512
        # This creates a type 10 secret compatible with IOS-XR
        local password_hash
        password_hash=$(python3 -c "import crypt; print(crypt.crypt('$FALLBACK_LOCAL_PASSWORD', crypt.mksalt(crypt.METHOD_SHA512)))")
        
        if [[ -z "$password_hash" ]]; then
            print_error "Failed to generate password hash" >&2
            exit 1
        fi
        
        config="username $FALLBACK_LOCAL_USERNAME
 group root-lr
 group cisco-support
 secret 10 $password_hash
!"
    else
        print_info "Fallback local user environment variables not set, using default configuration" >&2
        config=$(cat "$FALLBACK_CONFIG_FILE")
    fi
    
    echo "$config"
}

# Function to inject configuration into startup file
inject_config_to_file() {
    local startup_file="$1"
    local tacacs_config="$2"
    local temp_file="${startup_file}.tmp"
    
    if [[ ! -f "$startup_file" ]]; then
        print_error "Startup file not found: $startup_file"
        return 1
    fi
    
    # Check if file already contains username configuration
    if grep -q "^username " "$startup_file"; then
        print_info "$(basename "$startup_file") already contains username configuration, skipping..."
        return 0
    fi
    
    # Create temporary file with injected config at the beginning
    {
        echo "$tacacs_config"
        cat "$startup_file"
    } > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$startup_file"
    
    print_success "Configuration injected into $(basename "$startup_file")"
}

# Generate the local user configuration
LOCAL_USER_CONFIG=$(generate_local_user_config)

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
        inject_config_to_file "$startup_file" "$LOCAL_USER_CONFIG"
    fi
done

print_success "Local user configuration injection completed successfully!"
print_info "Note: Configuration has been injected at the beginning of each startup file"

if [[ -n "$FALLBACK_LOCAL_USERNAME" && -n "$FALLBACK_LOCAL_PASSWORD" ]]; then
    print_info "Used credentials: Username=$FALLBACK_LOCAL_USERNAME"
else
    print_info "Used default local user configuration from $FALLBACK_CONFIG_FILE"
fi
