#!/usr/bin/env bash

# Script to load XRd container into Docker/Podman
# This script handles both direct container format and nested archive format
# It can work with either the original archive or extracted content

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root directory (parent of scripts directory)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$SCRIPT_DIR/common_utils.sh"

# Source format detection utilities
source "$SCRIPT_DIR/xrd-format-utils.sh"

# Initialize environment (load env vars, validate, detect container engine)
if ! init_sandbox_environment "XRD_CONTAINER_VERSION" "XRD_CONTAINER_ARCHIVE"; then
    exit 1
fi

# Define paths
ARCHIVE_PATH="$PROJECT_ROOT/$XRD_CONTAINER_ARCHIVE"
EXTRACT_DIR="$PROJECT_ROOT/xrd-container"
IMAGE_INFO=$(get_xrd_image_info)

print_info "XRd Container $CONTAINER_ENGINE_NAME Load Script"
print_info "==============================================="
print_info "Project root: $PROJECT_ROOT"
print_info "Target image: $IMAGE_INFO"
echo ""

# Function to load container from file
load_container() {
    local container_file="$1"
    local file_type="$2"
    
    print_info "Loading container from: $container_file"
    print_info "File type: $file_type"
    
    if ! validate_file_exists "$container_file" "Container file"; then
        return 1
    fi
    
    if ! is_valid_container "$container_file"; then
        print_error "Invalid container file: $container_file"
        return 1
    fi
    
    print_info "Loading into $CONTAINER_ENGINE_NAME..."
    if $CONTAINER_ENGINE load < "$container_file"; then
        print_success "Successfully loaded container into $CONTAINER_ENGINE_NAME!"
        echo ""
        print_info "Checking loaded images:"
        $CONTAINER_ENGINE images | grep -E "(REPOSITORY|xrd|control-plane)" || $CONTAINER_ENGINE images | head -5
        echo ""
        
        # Try to tag the image if we can identify it
        if $CONTAINER_ENGINE images --format "table {{.Repository}}:{{.Tag}}" | grep -q "xrd-control-plane"; then
            local loaded_image=$($CONTAINER_ENGINE images --format "{{.Repository}}:{{.Tag}}" | grep "xrd-control-plane" | head -1)
            if [[ "$loaded_image" != "$IMAGE_INFO" ]]; then
                print_info "Tagging image as $IMAGE_INFO..."
                $CONTAINER_ENGINE tag "$loaded_image" "$IMAGE_INFO" || print_warning "Could not tag image"
            fi
        fi
        
        return 0
    else
        print_error "Failed to load container into $CONTAINER_ENGINE_NAME"
        return 1
    fi
}

# Check what's available and determine the approach
if [[ -f "$ARCHIVE_PATH" ]] && [[ ! -d "$EXTRACT_DIR" ]]; then
    # Archive exists but not extracted - detect format and handle accordingly
    print_info "Archive found but not extracted. Analyzing format..."
    
    ARCHIVE_FORMAT=$(detect_xrd_format "$ARCHIVE_PATH")
    show_format_info "$ARCHIVE_FORMAT" "$ARCHIVE_PATH"
    
    case "$ARCHIVE_FORMAT" in
        "container")
            print_info "Loading directly from archive (container format)..."
            load_container "$ARCHIVE_PATH" "Direct container archive"
            ;;
        "nested")
            print_warning "Archive contains nested structure. Extraction required."
            print_info "Please run './scripts/extract-xrd-container.sh' first, then run this script again."
            exit 1
            ;;
        *)
            print_warning "Unknown format. Please extract first using './scripts/extract-xrd-container.sh'"
            exit 1
            ;;
    esac
    
elif [[ -d "$EXTRACT_DIR" ]]; then
    # Extracted directory exists - find and load the container
    print_info "Using extracted content from: $EXTRACT_DIR"
    
    # First, check if this is a direct container extraction (manifest.json at root)
    if [[ -f "$EXTRACT_DIR/manifest.json" ]]; then
        print_info "Direct container format detected in extracted content."
        
        # Create a temporary tar file from the extracted content
        TEMP_TAR=$(mktemp --suffix=.tar)
        print_info "Creating temporary container file: $TEMP_TAR"
        
        cd "$EXTRACT_DIR"
        tar -cf "$TEMP_TAR" .
        cd - > /dev/null
        
        load_container "$TEMP_TAR" "Temporary container from extraction"
        
        # Clean up temporary file
        rm -f "$TEMP_TAR"
        print_info "Temporary file cleaned up."
        
    else
        # Look for nested container files
        print_info "Searching for container files in extracted content..."
        
        CONTAINER_FILE=$(find_container_file "$EXTRACT_DIR")
        if [[ -n "$CONTAINER_FILE" ]]; then
            load_container "$CONTAINER_FILE" "Container file from nested structure"
        else
            print_error "No valid container file found in $EXTRACT_DIR"
            echo ""
            print_info "Directory contents:"
            ls -la "$EXTRACT_DIR"
            echo ""
            print_error "Please ensure the archive was extracted properly or contains valid container files."
            exit 1
        fi
    fi
    
elif [[ -f "$ARCHIVE_PATH" ]] && [[ -d "$EXTRACT_DIR" ]]; then
    # Both archive and extracted content exist - prefer extracted content
    print_info "Both archive and extracted content exist. Using extracted content..."
    # Re-run the script logic for extracted directory
    exec "$0"
    
else
    print_error "Neither archive file nor extracted content found."
    print_info "Expected archive: $ARCHIVE_PATH"
    print_info "Expected extract directory: $EXTRACT_DIR"
    echo ""
    print_info "Please ensure you have either:"
    print_info "1. The original archive file: $XRD_CONTAINER_ARCHIVE"
    print_info "2. Extracted content in: $EXTRACT_DIR (run './scripts/extract-xrd-container.sh' first)"
    exit 1
fi

echo ""
print_success "$CONTAINER_ENGINE_NAME load process completed!"
echo ""
print_info "You can now use the XRd container with $CONTAINER_ENGINE_NAME Compose or $CONTAINER_ENGINE_NAME run commands."