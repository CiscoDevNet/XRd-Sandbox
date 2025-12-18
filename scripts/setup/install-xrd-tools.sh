#!/usr/bin/env bash

# Script to clone xrd-tools repository and add its scripts to PATH
# This script clones the xrd-tools repo and sets up the PATH for the current session

set -euo pipefail  # Exit on error, unset vars, and pipeline failures

# Get the script directory to find common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../lib/common.sh"
# Project root directory - XRd Sandbox root (fixed path)
readonly PROJECT_ROOT="/home/developer/XRd-Sandbox"
XRD_TOOLS_DIR="$PROJECT_ROOT/xrd-tools"

# Source common utilities
if [[ -f "$COMMON_UTILS" ]]; then
    source "$COMMON_UTILS"
else
    echo "ERROR: Common utilities not found: $COMMON_UTILS"
    exit 1
fi

print_info "Setting up xrd-tools repository and PATH"
print_info "========================================"

# Clone or update xrd-tools repository
if [ -d "$XRD_TOOLS_DIR" ]; then
    print_info "xrd-tools directory already exists at: $XRD_TOOLS_DIR"
    print_info "Updating existing repository..."
    cd "$XRD_TOOLS_DIR"
    if git pull origin main >/dev/null 2>&1; then
        print_success "xrd-tools repository updated successfully"
    else
        print_warning "Failed to update xrd-tools repository, continuing with existing version"
    fi
    cd - >/dev/null
else
    print_info "Cloning xrd-tools repository..."
    if git clone https://github.com/ios-xr/xrd-tools.git "$XRD_TOOLS_DIR" >/dev/null 2>&1; then
        print_success "xrd-tools repository cloned successfully to: $XRD_TOOLS_DIR"
    else
        print_error "Failed to clone xrd-tools repository"
        exit 1
    fi
fi

# Set read-only permissions to prevent modifications
print_info "Setting read-only permissions on xrd-tools repository..."

# Remove write permissions for all users (owner, group, others)
if chmod -R a-w "$XRD_TOOLS_DIR"; then
    print_success "Write permissions removed from xrd-tools repository"
else
    print_warning "Failed to remove write permissions"
fi

# Additionally, make scripts executable but not writable
if find "$XRD_TOOLS_DIR" -name "*.py" -o -name "xr-compose" -o -name "host-check" -o -name "launch-xrd" -o -name "apply-bugfixes" | xargs chmod a+x,a-w 2>/dev/null; then
    print_success "Script files set to executable but read-only"
else
    print_info "Some script permission updates may have failed (non-critical)"
fi

# Set directory permissions to allow traversal but prevent modifications
find "$XRD_TOOLS_DIR" -type d -exec chmod a+rx,a-w {} \; 2>/dev/null || print_warning "Some directory permission updates failed"

# Ensure parent directories are traversable by all users
# This is critical for other users to access xrd-tools scripts
print_info "Ensuring parent directories are accessible to all users..."
chmod o+x "$PROJECT_ROOT" 2>/dev/null || print_warning "Could not modify permissions on $PROJECT_ROOT"
chmod o+x "$(dirname "$PROJECT_ROOT")" 2>/dev/null || print_warning "Could not modify permissions on parent directory"

print_success "xrd-tools repository secured with read-only permissions"

# Verify the scripts directory exists
XRD_SCRIPTS_DIR="$XRD_TOOLS_DIR/scripts"
if [ ! -d "$XRD_SCRIPTS_DIR" ]; then
    print_error "xrd-tools scripts directory not found: $XRD_SCRIPTS_DIR"
    exit 1
fi

print_success "xrd-tools scripts directory found: $XRD_SCRIPTS_DIR"

# List available scripts
print_info "Available xrd-tools scripts:"
for script in "$XRD_SCRIPTS_DIR"/*; do
    if [ -x "$script" ] && [ -f "$script" ]; then
        script_name=$(basename "$script")
        print_info "  - $script_name"
    fi
done

# Add xrd-tools scripts to PATH for current session
if [[ ":$PATH:" != *":$XRD_SCRIPTS_DIR:"* ]]; then
    export PATH="$XRD_SCRIPTS_DIR:$PATH"
    print_success "Added xrd-tools scripts to PATH for current session"
else
    print_info "xrd-tools scripts already in PATH"
fi

# Setup system-wide PATH configuration for all users
# This ensures xrd-tools is available in all shells, including su -c commands
PROFILE_D_FILE="/etc/profile.d/xrd-tools.sh"
PATH_EXPORT_LINE="export PATH=\"$XRD_SCRIPTS_DIR:\$PATH\""
PATH_COMMENT="# Added by XRd-Sandbox for xrd-tools scripts - available to all users"

print_info "Setting up system-wide PATH configuration for all users..."
if [ -d "/etc/profile.d" ]; then
    # Create the profile.d script
    echo "$PATH_COMMENT" | tee "$PROFILE_D_FILE" >/dev/null
    echo "$PATH_EXPORT_LINE" | tee -a "$PROFILE_D_FILE" >/dev/null
    chmod 644 "$PROFILE_D_FILE"
    print_success "Created system-wide PATH configuration: $PROFILE_D_FILE"
    print_info "All users will have access to xrd-tools scripts"
else
    print_warning "/etc/profile.d not found, skipping system-wide configuration"
fi

# Verify the tools are accessible
print_info "Verifying tool accessibility..."
if command -v xr-compose >/dev/null 2>&1; then
    print_success "xr-compose is accessible in PATH"
    xr_compose_version=$(xr-compose --version 2>/dev/null || echo "version check failed")
    print_info "xr-compose version: $xr_compose_version"
else
    print_error "xr-compose not accessible in PATH"
    print_info "You may need to source your shell profile or start a new terminal session"
    print_info "Try: source ~/.bashrc (or your shell profile)"
    exit 1
fi

echo ""
print_success "xrd-tools setup completed successfully!"
print_info "PATH has been configured system-wide for all users"
print_info "Available commands: xr-compose, host-check, launch-xrd, apply-bugfixes"
print_info ""
print_info "To use these tools in the current shell, you can either:"
print_info "  1. Start a new login shell (logout and login, or 'su - <user>')"
print_info "  2. Source the profile: source /etc/profile.d/xrd-tools.sh"
print_info "  3. Run in a login shell: bash -lc '<command>'"
print_info ""
print_info "The tools are installed at: $XRD_SCRIPTS_DIR"