#!/usr/bin/env bash

# Script to extract XRd container archive
# This script extracts the XRd control plane container archive to a version-independent directory
# Supports both direct container format and nested archive format

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root directory - XRd Sandbox root (fixed path)
readonly PROJECT_ROOT="/home/developer/XRd-Sandbox"

# Source common utilities
source "$SCRIPT_DIR/../lib/common.sh"

# Source format detection utilities
source "$SCRIPT_DIR/../lib/container-format.sh"

# Initialize environment (load env vars, validate, detect container engine)
if ! init_sandbox_environment "XRD_CONTAINER_VERSION" "XRD_CONTAINER_ARCHIVE"; then
    exit 1
fi

# Define paths
ARCHIVE_PATH="$PROJECT_ROOT/$XRD_CONTAINER_ARCHIVE"
EXTRACT_DIR="$PROJECT_ROOT/xrd-container"

print_info "XRd Container Archive Extraction Script"
print_info "======================================="
print_info "Project root: $PROJECT_ROOT"
print_info "Archive file: $ARCHIVE_PATH"
print_info "Extract to: $EXTRACT_DIR"
echo ""

# Validate archive file exists
if ! validate_file_exists "$ARCHIVE_PATH" "XRd Container Archive"; then
    exit 1
fi

# Detect archive format
print_info "Detecting archive format..."
ARCHIVE_FORMAT=$(detect_xrd_format "$ARCHIVE_PATH")
if [[ $? -ne 0 ]]; then
    print_error "Failed to detect archive format"
    exit 1
fi

show_format_info "$ARCHIVE_FORMAT" "$ARCHIVE_PATH"

# Create extraction directory if it doesn't exist, or clean existing one
if [[ ! -d "$EXTRACT_DIR" ]]; then
    print_info "Creating extraction directory: $EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"
else
    print_warning "Extraction directory already exists: $EXTRACT_DIR"
    print_info "Removing existing content and continuing with extraction..."
    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"
fi

# Extract the archive based on format
print_info "Extracting $XRD_CONTAINER_ARCHIVE..."
print_info "This may take a few moments..."

case "$ARCHIVE_FORMAT" in
    "container")
        print_info "Processing direct container format..."
        if tar -tzf "$ARCHIVE_PATH" > /dev/null 2>&1; then
            tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR" --strip-components=0
            print_success "Direct container extraction completed!"
        else
            print_error "Invalid or corrupted archive file: $ARCHIVE_PATH"
            exit 1
        fi
        ;;
    "nested")
        print_info "Processing nested archive format..."
        if tar -tzf "$ARCHIVE_PATH" > /dev/null 2>&1; then
            tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR" --strip-components=0
            print_success "Nested archive extraction completed!"
            echo ""
            print_info "Looking for container files in extracted content..."
            
            # Find the actual container file
            CONTAINER_FILE=$(find_container_file "$EXTRACT_DIR")
            if [[ -n "$CONTAINER_FILE" ]]; then
                print_success "Found container file: $(basename "$CONTAINER_FILE")"
                print_info "Container file location: $CONTAINER_FILE"
            else
                print_warning "No container file (.tgz or .tar) found in extracted content"
                print_info "You may need to manually locate the container file for Docker loading"
            fi
        else
            print_error "Invalid or corrupted archive file: $ARCHIVE_PATH"
            exit 1
        fi
        ;;
    *)
        print_warning "Unknown format '$ARCHIVE_FORMAT', attempting nested extraction..."
        if tar -tzf "$ARCHIVE_PATH" > /dev/null 2>&1; then
            tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR" --strip-components=0
            print_success "Extraction completed (format unknown)!"
        else
            print_error "Invalid or corrupted archive file: $ARCHIVE_PATH"
            exit 1
        fi
        ;;
esac

echo ""
print_success "Contents extracted to: $EXTRACT_DIR"
print_info "Directory contents:"
ls -la "$EXTRACT_DIR"

echo ""
print_success "Extraction process finished."
echo ""
print_info "Next steps:"
print_info "- Use './scripts/setup/load-container.sh' to load the container into $CONTAINER_ENGINE_NAME"
print_info "- The load script will automatically detect and handle the correct format"