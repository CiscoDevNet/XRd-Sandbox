#!/usr/bin/env bash

# Script to clone xrd-tools repository and add its scripts to PATH
# This script clones the xrd-tools repo and sets up the PATH for the current session

set -e  # Exit on any error

# Get the script directory to find common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/common_utils.sh"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
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

# Define the target user for PATH setup (developer user)
DEVELOPER_USER="developer"
DEVELOPER_HOME="/home/$DEVELOPER_USER"

# Verify developer user exists
if ! id "$DEVELOPER_USER" &>/dev/null; then
    print_error "Developer user '$DEVELOPER_USER' does not exist"
    exit 1
fi

# Create or update shell profile entries for persistent PATH (for developer user)
SHELL_PROFILES=("$DEVELOPER_HOME/.bashrc" "$DEVELOPER_HOME/.bash_profile" "$DEVELOPER_HOME/.zshrc")
PATH_EXPORT_LINE="export PATH=\"$XRD_SCRIPTS_DIR:\$PATH\""
PATH_COMMENT="# Added by XRd-Sandbox for xrd-tools scripts"

print_info "Setting up persistent PATH in shell profiles for user '$DEVELOPER_USER'..."
for profile in "${SHELL_PROFILES[@]}"; do
    if [ -f "$profile" ]; then
        # Remove any existing xrd-tools PATH entries to avoid duplicates
        sed -i '/xrd-tools.*scripts/d' "$profile"
        # Add the new PATH entry
        echo "" >> "$profile"
        echo "$PATH_COMMENT" >> "$profile"
        echo "$PATH_EXPORT_LINE" >> "$profile"
        # Ensure proper ownership
        chown "$DEVELOPER_USER:$DEVELOPER_USER" "$profile"
        print_success "Updated PATH in $profile"
    elif [ "$profile" = "$DEVELOPER_HOME/.bashrc" ]; then
        # Always create .bashrc if it doesn't exist (most important for login shells)
        print_info "Creating $profile for user '$DEVELOPER_USER'"
        echo "$PATH_COMMENT" > "$profile"
        echo "$PATH_EXPORT_LINE" >> "$profile"
        chown "$DEVELOPER_USER:$DEVELOPER_USER" "$profile"
        print_success "Created and updated PATH in $profile"
    fi
done

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
print_info "PATH has been configured for user '$DEVELOPER_USER'"
print_info "Available commands: xr-compose, host-check, launch-xrd, apply-bugfixes"
print_info ""
print_info "For the developer user to use these tools, they need to:"
print_info "  source ~/.bashrc   # or their shell profile"
print_info "  or start a new terminal session"
print_info ""
print_info "The tools will be available at: $XRD_SCRIPTS_DIR"