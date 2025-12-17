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

print_info "Starting TACACS configuration injection for Always-On sandbox..."

# Check if TACACS environment variables are set
missing_vars=()
[[ -z "$TACACS_SERVER_HOST" ]] && missing_vars+=("TACACS_SERVER_HOST")
[[ -z "$TACACS_SERVER_SECRET" ]] && missing_vars+=("TACACS_SERVER_SECRET")

if [[ ${#missing_vars[@]} -eq 2 ]]; then
    print_info "TACACS environment variables not set: ${missing_vars[*]}"
    print_info "Skipping TACACS configuration injection - no changes will be made"
    exit 0
elif [[ ${#missing_vars[@]} -eq 1 ]]; then
    print_error "Missing required TACACS environment variable: ${missing_vars[*]}"
    print_error "Both TACACS_SERVER_HOST and TACACS_SERVER_SECRET are required for TACACS configuration"
    exit 1
fi

print_info "TACACS environment variables detected:"
print_info "  TACACS_SERVER_HOST: $TACACS_SERVER_HOST"
print_info "  TACACS_SERVER_SECRET: [REDACTED]"

# Define paths - support TEST_MODE for testing
if [[ -n "$TEST_MODE" ]]; then
    TOPOLOGY_DIR="$TEST_MODE/output"
    print_info "TEST_MODE enabled: Using test directories"
else
    TOPOLOGY_DIR="$SANDBOX_ROOT/topologies/always-on"
fi

# Validate topology directory exists
if [[ ! -d "$TOPOLOGY_DIR" ]]; then
    print_error "Topology directory not found: $TOPOLOGY_DIR"
    exit 1
fi

# Generate TACACS configuration
generate_tacacs_config() {
    cat <<EOF
!
tacacs source-interface MgmtEth0/RP0/CPU0/0 vrf default
tacacs-server host $TACACS_SERVER_HOST port 49
 key 0 $TACACS_SERVER_SECRET
!
EOF
}

# Function to inject configuration into startup file
# Returns: prints "SKIPPED" if config exists, "INJECTED" if config was added, or exits on error
inject_config_to_file() {
    local startup_file="$1"
    local tacacs_config="$2"
    local temp_file="${startup_file}.tmp"
    
    if [[ ! -f "$startup_file" ]]; then
        print_error "Startup file not found: $startup_file"
        return 1
    fi
    
    # Check if TACACS configuration already exists in the file
    if grep -q "tacacs source-interface" "$startup_file" || \
       grep -q "tacacs-server host" "$startup_file"; then
        print_info "$(basename "$startup_file") already contains TACACS configuration, skipping..." >&2
        echo "SKIPPED"
        return 0
    fi
    
    # Create temporary file with injected config at the beginning
    {
        echo "$tacacs_config"
        cat "$startup_file"
    } > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$startup_file"
    
    print_success "TACACS configuration injected into $(basename "$startup_file")" >&2
    echo "INJECTED"
    return 0
}

# Generate the TACACS configuration
TACACS_CONFIG=$(generate_tacacs_config)

# Find all deployment startup.cfg files in the topology directory
print_info "Searching for deployment configuration files in $TOPOLOGY_DIR..."

startup_files=("$TOPOLOGY_DIR"/xrd-*-startup.deploy.cfg)

if [[ ${#startup_files[@]} -eq 0 ]] || [[ ! -f "${startup_files[0]}" ]]; then
    print_error "No deployment configuration files found in $TOPOLOGY_DIR"
    print_error "Expected files: xrd-*-startup.deploy.cfg"
    print_error "These files should be created by the deploy.sh script before running injection scripts"
    exit 1
fi

print_info "Found ${#startup_files[@]} deployment configuration file(s)"

# Inject configuration into each startup file
files_injected=0
files_skipped=0

for startup_file in "${startup_files[@]}"; do
    result=$(inject_config_to_file "$startup_file" "$TACACS_CONFIG")
    if [[ "$result" == "INJECTED" ]]; then
        (( files_injected++ )) || true
    elif [[ "$result" == "SKIPPED" ]]; then
        (( files_skipped++ )) || true
    fi
done

# Summary and exit
if [[ $files_injected -eq 0 && $files_skipped -gt 0 ]]; then
    print_info "All startup files already contain TACACS configuration - no changes made"
    exit 0
fi

if [[ $files_injected -gt 0 ]]; then
    print_success "TACACS configuration injection completed successfully"
    print_info "Files updated: $files_injected, Files skipped: $files_skipped"
fi
