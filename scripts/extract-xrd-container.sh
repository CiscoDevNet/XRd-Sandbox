#!/bin/bash

# Script to extract XRd container archive
# This script extracts the XRd control plane container archive to a version-independent directory
# Supports both direct container format and nested archive format

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

echo "XRd Container Archive Extraction Script"
echo "======================================="
echo "Project root: $PROJECT_ROOT"
echo "Archive file: $ARCHIVE_PATH"
echo "Extract to: $EXTRACT_DIR"
echo ""

# Check if archive file exists
if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "Error: Archive file not found at $ARCHIVE_PATH"
    echo "Expected file: $XRD_CONTAINER_ARCHIVE"
    exit 1
fi

# Detect archive format
echo "Detecting archive format..."
ARCHIVE_FORMAT=$(detect_xrd_format "$ARCHIVE_PATH")
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to detect archive format"
    exit 1
fi

show_format_info "$ARCHIVE_FORMAT" "$ARCHIVE_PATH"

# Create extraction directory if it doesn't exist
if [[ ! -d "$EXTRACT_DIR" ]]; then
    echo "Creating extraction directory: $EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"
else
    echo "Warning: Extraction directory already exists: $EXTRACT_DIR"
    read -p "Do you want to continue and potentially overwrite existing files? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Extraction cancelled."
        exit 0
    fi
fi

# Extract the archive based on format
echo "Extracting $XRD_CONTAINER_ARCHIVE..."
echo "This may take a few moments..."

case "$ARCHIVE_FORMAT" in
    "container")
        echo "Processing direct container format..."
        if tar -tzf "$ARCHIVE_PATH" > /dev/null 2>&1; then
            tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR" --strip-components=0
            echo "Direct container extraction completed!"
        else
            echo "Error: Invalid or corrupted archive file: $ARCHIVE_PATH"
            exit 1
        fi
        ;;
    "nested")
        echo "Processing nested archive format..."
        if tar -tzf "$ARCHIVE_PATH" > /dev/null 2>&1; then
            tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR" --strip-components=0
            echo "Nested archive extraction completed!"
            echo ""
            echo "Looking for container files in extracted content..."
            
            # Find the actual container file
            CONTAINER_FILE=$(find_container_file "$EXTRACT_DIR")
            if [[ -n "$CONTAINER_FILE" ]]; then
                echo "Found container file: $(basename "$CONTAINER_FILE")"
                echo "Container file location: $CONTAINER_FILE"
            else
                echo "Warning: No container file (.tgz or .tar) found in extracted content"
                echo "You may need to manually locate the container file for Docker loading"
            fi
        else
            echo "Error: Invalid or corrupted archive file: $ARCHIVE_PATH"
            exit 1
        fi
        ;;
    *)
        echo "Warning: Unknown format '$ARCHIVE_FORMAT', attempting nested extraction..."
        if tar -tzf "$ARCHIVE_PATH" > /dev/null 2>&1; then
            tar -xzf "$ARCHIVE_PATH" -C "$EXTRACT_DIR" --strip-components=0
            echo "Extraction completed (format unknown)!"
        else
            echo "Error: Invalid or corrupted archive file: $ARCHIVE_PATH"
            exit 1
        fi
        ;;
esac

echo ""
echo "Contents extracted to: $EXTRACT_DIR"
echo "Directory contents:"
ls -la "$EXTRACT_DIR"

echo ""
echo "Extraction process finished."
echo ""
echo "Next steps:"
echo "- Use './scripts/load-xrd-container.sh' to load the container into Docker"
echo "- The load script will automatically detect and handle the correct format"