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
TOPOLOGY_DIR="$SANDBOX_ROOT/topologies/always-on"
AAA_CONFIG_FILE="$TOPOLOGY_DIR/aaa-config.cfg"

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
# Returns: prints "SKIPPED" if config exists, "INJECTED" if config was added, or exits on error
inject_config_to_file() {
    local startup_file="$1"
    local aaa_config="$2"
    local temp_file="${startup_file}.tmp"
    
    if [[ ! -f "$startup_file" ]]; then
        print_error "Startup file not found: $startup_file"
        return 1
    fi
    
    # Check if AAA configuration already exists in the file
    # Look for key AAA configuration markers
    if grep -q "^aaa accounting exec" "$startup_file" || \
       grep -q "^aaa authorization exec" "$startup_file" || \
       grep -q "^aaa authentication login" "$startup_file"; then
        print_info "$(basename "$startup_file") already contains AAA configuration, skipping..." >&2
        echo "SKIPPED"
        return 0
    fi
    
    # Create temporary file with injected config at the beginning
    {
        echo "$aaa_config"
        cat "$startup_file"
    } > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$startup_file"
    
    print_success "AAA configuration injected into $(basename "$startup_file")" >&2
    echo "INJECTED"
    return 0
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
files_injected=0
files_skipped=0

for startup_file in "${startup_files[@]}"; do
    if [[ -f "$startup_file" ]]; then
        print_info "Processing $(basename "$startup_file")..."
        result=$(inject_config_to_file "$startup_file" "$AAA_CONFIG")
        if [[ "$result" == "INJECTED" ]]; then
            (( files_injected++ )) || true
        elif [[ "$result" == "SKIPPED" ]]; then
            (( files_skipped++ )) || true
        fi
    fi
done

# Summary and exit
if [[ $files_injected -eq 0 && $files_skipped -gt 0 ]]; then
    print_info "All startup files already contain AAA configuration - no changes made"
    exit 0
fi

if [[ $files_injected -gt 0 ]]; then
    print_success "TACACS AAA configuration injection completed successfully!"
    print_info "Files updated: $files_injected, Files skipped: $files_skipped"
    print_info "The AAA configuration will work in conjunction with TACACS server at $TACACS_SERVER_IP"
fi
