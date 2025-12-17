#!/usr/bin/env bash

# Script to validate the environment for XRd Sandbox
# This script performs all necessary checks without executing deployment tasks
# Useful for CI/CD pipeline health checks
# 
# IMPORTANT: This validation is performed for the developer user environment,
# regardless of which user executes the script (ubuntu for building vs developer for usage).
# 
# The script validates:
# - Developer user exists and has proper home directory
# - xr-compose tool is accessible to the developer user
# - Container engine works for the developer user
# - Required files exist and are accessible
# - XRd container images are accessible to the developer user
# - Developer user's shell environment is properly configured
#
# This addresses the common issue where validation scripts run as 'ubuntu' user
# during CI/CD builds, but need to validate the environment for 'developer' user
# who will actually use the XRd Sandbox.

set -eo pipefail  # Exit on error, catch pipeline failures

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

# Define target user for validation
readonly DEVELOPER_USER="developer"
readonly DEVELOPER_HOME="/home/$DEVELOPER_USER"

# Function to run command as developer user (using utility function)
run_as_developer() {
    local cmd="$1"
    run_as_user "$DEVELOPER_USER" "$cmd"
}

# Function to validate developer user exists
validate_developer_user() {
    print_info "Validating developer user environment..."
    
    if validate_user_exists "$DEVELOPER_USER"; then
        print_success "Developer user '$DEVELOPER_USER' exists with home directory: $DEVELOPER_HOME"
        return 0
    else
        print_info "This environment requires a '$DEVELOPER_USER' user to be properly configured"
        return 1
    fi
}

print_info "XRd Sandbox Environment Validation"
print_info "=================================="
print_info "Current user: $(whoami)"
print_info "Target validation user: $DEVELOPER_USER"

# Validate developer user exists
if ! validate_developer_user; then
    exit 1
fi

# Force SANDBOX_ROOT to be the XRd Sandbox project root (fixed path)
# This ensures correct path when running as root via sudo
readonly SCRIPT_SANDBOX_ROOT="/home/developer/XRd-Sandbox"
export SANDBOX_ROOT="$SCRIPT_SANDBOX_ROOT"

print_info "Script location: $SCRIPT_DIR"
print_info "Forced SANDBOX_ROOT: $SANDBOX_ROOT"

# Initialize environment with all required variables
if ! init_sandbox_environment "XRD_CONTAINER_VERSION" "XRD_CONTAINER_ARCHIVE" "SANDBOX_ROOT" "SANDBOX_IP"; then
    print_error "Environment initialization failed"
    exit 1
fi

print_success "Environment variables loaded successfully"
print_info "XRD_CONTAINER_VERSION: $XRD_CONTAINER_VERSION"
print_info "SANDBOX_ROOT: $SANDBOX_ROOT"
print_info "Container Engine: $CONTAINER_ENGINE_NAME"

# Check if xr-compose tool is available for developer user
print_info "Checking for xr-compose tool availability for user '$DEVELOPER_USER'..."

# Define the expected xrd-tools path (hardcoded for developer user validation)
xrd_tools_path="$SANDBOX_ROOT/xrd-tools/scripts"
xr_compose_direct="$xrd_tools_path/xr-compose"

# First, check if xr-compose exists at the expected location
if [[ -x "$xr_compose_direct" ]]; then
    print_success "xr-compose executable found at: $xr_compose_direct"
    
    # Test if it works when called directly
    if run_as_developer "'$xr_compose_direct' --help >/dev/null 2>&1"; then
        print_success "xr-compose is functional for user '$DEVELOPER_USER'"
        
        # Now check PATH configuration for informational purposes
        # Try with interactive shell (bash -l) to get proper PATH loading
        interactive_path_check=$(run_as_developer "bash -l -c 'command -v xr-compose 2>/dev/null'" || echo "")
        
        if [[ -n "$interactive_path_check" ]]; then
            print_success "xr-compose is also available in interactive PATH"
            print_info "Interactive shell PATH includes xrd-tools correctly"
        else
            print_info "xr-compose works directly but may not be in non-interactive PATH"
            print_info "This is normal due to .bashrc interactive shell check"
            print_info "Users will have access to xr-compose in normal terminal sessions"
        fi
    else
        print_error "xr-compose exists but is not functional"
        exit 1
    fi
else
    print_error "xr-compose tool not found at expected location: $xr_compose_direct"
    
    if [[ -d "$xrd_tools_path" ]]; then
        print_info "xrd-tools directory exists but xr-compose is missing or not executable"
        print_info "Contents of $xrd_tools_path:"
        ls -la "$xrd_tools_path" | head -10
    else
        print_info "xrd-tools directory not found at: $xrd_tools_path"
        print_info "Run 'make clone-xrd-tools' to clone and set up xrd-tools"
    fi
    exit 1
fi

# Check if required files exist
print_info "Validating required files..."
# Project root directory - XRd Sandbox root (fixed path)
readonly PROJECT_ROOT="/home/developer/XRd-Sandbox"
ARCHIVE_PATH="$PROJECT_ROOT/$XRD_CONTAINER_ARCHIVE"

if validate_file_exists "$SANDBOX_ROOT/topologies/segment-routing/docker-compose.xr.yml" "Segment Routing template"; then
    print_success "Segment Routing template found"
else
    print_error "Segment Routing template not found"
    exit 1
fi

# Check container engine functionality for developer user
print_info "Testing container engine functionality for user '$DEVELOPER_USER'..."
if run_as_developer "$CONTAINER_ENGINE version >/dev/null 2>&1"; then
    print_success "Container engine ($CONTAINER_ENGINE_NAME) is working for user '$DEVELOPER_USER'"
else
    print_error "Container engine ($CONTAINER_ENGINE_NAME) is not responding for user '$DEVELOPER_USER'"
    print_info "The developer user may not have proper permissions or the container engine may not be accessible"
    print_info "Consider adding user '$DEVELOPER_USER' to the docker group or checking container engine installation"
    exit 1
fi

# Check if XRd image exists (optional check) - for developer user
print_info "Checking for XRd container image accessibility for user '$DEVELOPER_USER'..."
IMAGE_NAME=$(construct_xrd_image_name "$XRD_CONTAINER_VERSION")
if run_as_developer "$CONTAINER_ENGINE image inspect '$IMAGE_NAME' >/dev/null 2>&1"; then
    print_success "XRd container image is accessible to user '$DEVELOPER_USER': $IMAGE_NAME"
else
    print_info "XRd container image not accessible to user '$DEVELOPER_USER' (this is expected if not yet loaded)"
    print_info "Image will be loaded during setup process: $IMAGE_NAME"
    
    # Additional check: see if image exists but user can't access it
    if $CONTAINER_ENGINE image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        print_warning "Image exists but user '$DEVELOPER_USER' cannot access it (permission issue)"
        print_info "Consider adding user '$DEVELOPER_USER' to the docker group"
    fi
fi

# Validate developer user's shell environment
print_info "Validating developer user's shell environment..."
developer_shell=$(run_as_developer 'echo $SHELL')
print_info "Developer user's shell: $developer_shell"

# Check if PATH is properly configured for interactive shells
print_info "Checking PATH configuration for interactive shell sessions..."

# Check if xrd-tools is in interactive shell PATH (this is what users will experience)
interactive_path_check=$(run_as_developer "bash -l -c 'echo \$PATH | grep -q xrd-tools && echo \"yes\" || echo \"no\"'")

if [[ "$interactive_path_check" == "yes" ]]; then
    print_success "Developer user's PATH contains xrd-tools in interactive shells"
    print_info "Users will have access to xr-compose in normal terminal sessions"
else
    # Check if the PATH entry exists in .bashrc but is blocked by interactive check
    profile_check=$(run_as_developer 'grep -c "xrd-tools" ~/.bashrc 2>/dev/null || echo "0"')
    interactive_guard=$(run_as_developer 'grep -c "If not running interactively" ~/.bashrc 2>/dev/null || echo "0"')
    
    if [[ "$profile_check" -gt "0" ]] && [[ "$interactive_guard" -gt "0" ]]; then
        print_warning "xrd-tools PATH entry exists in .bashrc but is blocked by interactive shell guard"
        print_info "Found $profile_check xrd-tools entries in ~/.bashrc"
        print_info "The .bashrc has an interactive shell check that prevents PATH loading in scripts"
        print_info "This is normal bash behavior - users will have access in interactive terminals"
        
        # Verify this works in an actual interactive-style shell
        test_interactive=$(run_as_developer "bash -i -c 'echo \$PATH' 2>/dev/null | grep -q xrd-tools && echo 'yes' || echo 'no'" 2>/dev/null || echo 'no')
        if [[ "$test_interactive" == "yes" ]]; then
            print_success "Confirmed: PATH works correctly in interactive mode"
        fi
    else
        print_error "PATH is not properly configured for developer user"
        if [[ "$profile_check" -eq "0" ]]; then
            print_info "No xrd-tools entries found in ~/.bashrc"
            print_info "Run 'make clone-xrd-tools' to properly configure the PATH"
        fi
        exit 1
    fi
fi

echo ""
print_success "Environment validation completed successfully for user '$DEVELOPER_USER'!"
print_info "All required components are available for XRd Sandbox deployment"
print_info "The environment is ready for use by the developer user"