#!/bin/bash

# Script to load XRd container into Docker
# This script handles both direct container format and nested archive format
# It can work with either the original archive or extracted content

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root directory (parent of scripts directory)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source format detection utilities
source "$SCRIPT_DIR/xrd-format-utils.sh"

# Source environment variables (only if not already set)
if [[ -z "$XRD_CONTAINER_VERSION" ]] || [[ -z "$XRD_CONTAINER_ARCHIVE" ]]; then
    ENV_VARS_FILE="$PROJECT_ROOT/sandbox_env_vars.sh"
    if [[ ! -f "$ENV_VARS_FILE" ]]; then
        echo "Error: Environment variables file not found at $ENV_VARS_FILE"
        exit 1
    fi
    
    source "$ENV_VARS_FILE"
fi

# Validate required environment variables
if [[ -z "$XRD_CONTAINER_VERSION" ]]; then
    echo "Error: XRD_CONTAINER_VERSION is not set"
    exit 1
fi

if [[ -z "$XRD_CONTAINER_ARCHIVE" ]]; then
    echo "Error: XRD_CONTAINER_ARCHIVE is not set"
    exit 1
fi

# Define paths
ARCHIVE_PATH="$PROJECT_ROOT/$XRD_CONTAINER_ARCHIVE"
EXTRACT_DIR="$PROJECT_ROOT/xrd-container"
IMAGE_INFO=$(get_xrd_image_info)

echo "XRd Container Docker Load Script"
echo "==============================="
echo "Project root: $PROJECT_ROOT"
echo "Target image: $IMAGE_INFO"
echo ""

# Function to load container from file
load_container() {
    local container_file="$1"
    local file_type="$2"
    
    echo "Loading container from: $container_file"
    echo "File type: $file_type"
    
    if [[ ! -f "$container_file" ]]; then
        echo "Error: Container file not found: $container_file"
        return 1
    fi
    
    if ! is_valid_container "$container_file"; then
        echo "Error: Invalid container file: $container_file"
        return 1
    fi
    
    echo "Loading into Docker..."
    if docker load < "$container_file"; then
        echo "Successfully loaded container into Docker!"
        echo ""
        echo "Checking loaded images:"
        docker images | grep -E "(REPOSITORY|xrd|control-plane)" || docker images | head -5
        echo ""
        
        # Try to tag the image if we can identify it
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "xrd-control-plane"; then
            local loaded_image=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "xrd-control-plane" | head -1)
            if [[ "$loaded_image" != "$IMAGE_INFO" ]]; then
                echo "Tagging image as $IMAGE_INFO..."
                docker tag "$loaded_image" "$IMAGE_INFO" || echo "Warning: Could not tag image"
            fi
        fi
        
        return 0
    else
        echo "Error: Failed to load container into Docker"
        return 1
    fi
}

# Check what's available and determine the approach
if [[ -f "$ARCHIVE_PATH" ]] && [[ ! -d "$EXTRACT_DIR" ]]; then
    # Archive exists but not extracted - detect format and handle accordingly
    echo "Archive found but not extracted. Analyzing format..."
    
    ARCHIVE_FORMAT=$(detect_xrd_format "$ARCHIVE_PATH")
    show_format_info "$ARCHIVE_FORMAT" "$ARCHIVE_PATH"
    
    case "$ARCHIVE_FORMAT" in
        "container")
            echo "Loading directly from archive (container format)..."
            load_container "$ARCHIVE_PATH" "Direct container archive"
            ;;
        "nested")
            echo "Archive contains nested structure. Extraction required."
            echo "Please run './scripts/extract-xrd-container.sh' first, then run this script again."
            exit 1
            ;;
        *)
            echo "Unknown format. Please extract first using './scripts/extract-xrd-container.sh'"
            exit 1
            ;;
    esac
    
elif [[ -d "$EXTRACT_DIR" ]]; then
    # Extracted directory exists - find and load the container
    echo "Using extracted content from: $EXTRACT_DIR"
    
    # First, check if this is a direct container extraction (manifest.json at root)
    if [[ -f "$EXTRACT_DIR/manifest.json" ]]; then
        echo "Direct container format detected in extracted content."
        
        # Create a temporary tar file from the extracted content
        TEMP_TAR=$(mktemp --suffix=.tar)
        echo "Creating temporary container file: $TEMP_TAR"
        
        cd "$EXTRACT_DIR"
        tar -cf "$TEMP_TAR" .
        cd - > /dev/null
        
        load_container "$TEMP_TAR" "Temporary container from extraction"
        
        # Clean up temporary file
        rm -f "$TEMP_TAR"
        echo "Temporary file cleaned up."
        
    else
        # Look for nested container files
        echo "Searching for container files in extracted content..."
        
        CONTAINER_FILE=$(find_container_file "$EXTRACT_DIR")
        if [[ -n "$CONTAINER_FILE" ]]; then
            load_container "$CONTAINER_FILE" "Container file from nested structure"
        else
            echo "Error: No valid container file found in $EXTRACT_DIR"
            echo ""
            echo "Directory contents:"
            ls -la "$EXTRACT_DIR"
            echo ""
            echo "Please ensure the archive was extracted properly or contains valid container files."
            exit 1
        fi
    fi
    
elif [[ -f "$ARCHIVE_PATH" ]] && [[ -d "$EXTRACT_DIR" ]]; then
    # Both archive and extracted content exist - prefer extracted content
    echo "Both archive and extracted content exist. Using extracted content..."
    # Re-run the script logic for extracted directory
    exec "$0"
    
else
    echo "Error: Neither archive file nor extracted content found."
    echo "Expected archive: $ARCHIVE_PATH"
    echo "Expected extract directory: $EXTRACT_DIR"
    echo ""
    echo "Please ensure you have either:"
    echo "1. The original archive file: $XRD_CONTAINER_ARCHIVE"
    echo "2. Extracted content in: $EXTRACT_DIR (run './scripts/extract-xrd-container.sh' first)"
    exit 1
fi

echo ""
echo "Docker load process completed!"
echo ""
echo "You can now use the XRd container with Docker Compose or docker run commands."