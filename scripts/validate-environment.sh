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

# Force SANDBOX_ROOT to be based on the script location, not user's home
# This ensures correct path when running as root via sudo
SCRIPT_SANDBOX_ROOT="$(dirname "$SCRIPT_DIR")"
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

# First, try to find xr-compose in PATH with proper shell environment
xr_compose_check=$(run_as_developer "source ~/.bashrc 2>/dev/null; command -v xr-compose 2>/dev/null" || echo "")

if [[ -n "$xr_compose_check" ]]; then
    print_success "xr-compose tool is available for user '$DEVELOPER_USER'"
    print_info "xr-compose location: $xr_compose_check"
    
    # Test functionality (xr-compose doesn't support --version, so test help)
    if run_as_developer "source ~/.bashrc 2>/dev/null; xr-compose --help >/dev/null 2>&1"; then
        print_info "xr-compose functionality: Working correctly"
    else
        print_warning "xr-compose may have issues (help command failed)"
    fi
else
    # Check if xrd-tools directory exists and xr-compose is there
    xrd_tools_path="$SANDBOX_ROOT/xrd-tools/scripts"
    xr_compose_direct="$xrd_tools_path/xr-compose"
    
    if [[ -x "$xr_compose_direct" ]]; then
        print_warning "xr-compose executable exists but not in developer user's active PATH"
        print_info "xr-compose found at: $xr_compose_direct"
        
        # Test if it works when called directly (xr-compose doesn't support --version, so test help)
        if run_as_developer "source ~/.bashrc 2>/dev/null; '$xr_compose_direct' --help >/dev/null 2>&1"; then
            print_success "xr-compose is functional when called directly"
            print_info "The issue is with PATH configuration in interactive vs non-interactive shells"
            
            # Check current PATH
            current_path=$(run_as_developer "source ~/.bashrc 2>/dev/null; echo \$PATH")
            if [[ "$current_path" == *"xrd-tools"* ]]; then
                print_success "PATH contains xrd-tools after sourcing .bashrc - shell configuration is correct"
                print_info "xr-compose is accessible and functional for user '$DEVELOPER_USER'"
            else
                print_warning "PATH doesn't contain xrd-tools even after sourcing .bashrc"
                print_info "Developer user PATH: $current_path"
                print_info "But xr-compose is still functional via direct path"
            fi
        else
            print_error "xr-compose exists but is not functional"
            exit 1
        fi
    else
        print_error "xr-compose tool not found for user '$DEVELOPER_USER'"
        print_info "Run 'make clone-xrd-tools' to set up xrd-tools and add scripts to PATH"
        print_info "Developer user PATH: $(run_as_developer 'echo $PATH')"
        
        if [[ -d "$xrd_tools_path" ]]; then
            print_info "xrd-tools directory exists at: $xrd_tools_path"
            print_info "But xr-compose is missing or not executable"
        else
            print_info "xrd-tools directory not found at: $xrd_tools_path"
            print_info "Run 'make clone-xrd-tools' to clone and set up xrd-tools"
        fi
        exit 1
    fi
fi

# Check if required files exist
print_info "Validating required files..."
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
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

# Check if PATH persists in developer user's environment
# First check without sourcing profile (clean environment)
developer_path_clean=$(run_as_developer 'echo $PATH | grep -q xrd-tools && echo "yes" || echo "no"')
# Then check after sourcing profile
developer_path_sourced=$(run_as_developer 'source ~/.bashrc 2>/dev/null; echo $PATH | grep -q xrd-tools && echo "yes" || echo "no"')

if [[ "$developer_path_clean" == "yes" ]]; then
    print_success "Developer user's PATH contains xrd-tools directory (persistent)"
elif [[ "$developer_path_sourced" == "yes" ]]; then
    print_success "Developer user's PATH contains xrd-tools directory (after sourcing profile)"
    print_info "PATH is correctly configured in profile files"
else
    print_warning "Developer user's PATH does not contain xrd-tools directory"
    print_info "This may cause issues in new shell sessions"
    print_info "Verify that shell profile files (.bashrc, .bash_profile, .zshrc) are properly configured"
    
    # Additional diagnostic information
    profile_check=$(run_as_developer 'grep -c "xrd-tools" ~/.bashrc 2>/dev/null || echo "0"')
    if [[ "$profile_check" -gt "0" ]]; then
        print_info "Found $profile_check xrd-tools entries in ~/.bashrc"
        print_info "The PATH issue may be with shell initialization in non-interactive mode"
    else
        print_warning "No xrd-tools entries found in ~/.bashrc"
        print_info "Run 'make clone-xrd-tools' to properly configure the PATH"
    fi
fi

echo ""
print_success "Environment validation completed successfully for user '$DEVELOPER_USER'!"
print_info "All required components are available for XRd Sandbox deployment"
print_info "The environment is ready for use by the developer user"