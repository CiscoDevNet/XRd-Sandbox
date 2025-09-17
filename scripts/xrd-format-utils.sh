#!/bin/bash

# XRd Container Format Detection Utilities
# This file contains common functions for detecting and handling different XRd archive formats

# Function to detect XRd archive format
# Returns: "container" for direct container format, "nested" for nested archive format
detect_xrd_format() {
    local archive_path="$1"
    
    if [[ ! -f "$archive_path" ]]; then
        echo "Error: Archive file not found: $archive_path" >&2
        return 1
    fi
    
    # Get the list of top-level files in the archive
    local contents
    if ! contents=$(tar -tf "$archive_path" 2>/dev/null); then
        echo "Error: Cannot read archive contents: $archive_path" >&2
        return 1
    fi
    
    # Check for container format indicators (files at root level)
    if echo "$contents" | grep -q "^manifest\.json$"; then
        echo "container"
        return 0
    fi
    
    # Check for .tar files at root level (another container format indicator)
    if echo "$contents" | grep -q "\.tar$" | head -1 | grep -qv "/"; then
        echo "container"
        return 0
    fi
    
    # Check for nested structure (directories containing .tgz files)
    if echo "$contents" | grep -q "\.tgz$"; then
        echo "nested"
        return 0
    fi
    
    # Check for dockerv1 pattern (specific nested format indicator)
    if echo "$contents" | grep -q "dockerv1\.tgz"; then
        echo "nested"
        return 0
    fi
    
    # If we can't determine the format, default to nested for safety
    echo "nested"
    return 0
}

# Function to find the container file in a nested archive structure
find_container_file() {
    local extract_dir="$1"
    
    # Look for .tgz files in the extracted directory
    local container_file
    container_file=$(find "$extract_dir" -name "*.tgz" -type f | head -1)
    
    if [[ -n "$container_file" ]]; then
        echo "$container_file"
        return 0
    fi
    
    # Look for .tar files as fallback
    container_file=$(find "$extract_dir" -name "*.tar" -type f | head -1)
    
    if [[ -n "$container_file" ]]; then
        echo "$container_file"
        return 0
    fi
    
    return 1
}

# Function to validate if a file is a valid Docker container archive
is_valid_container() {
    local file_path="$1"
    
    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
        return 1
    fi
    
    # For .tgz files, check for manifest.json or .tar files
    if [[ "$file_path" == *.tgz ]] || [[ "$file_path" == *.tar.gz ]]; then
        if tar -tf "$file_path" 2>/dev/null | grep -q "manifest\.json\|\.tar$"; then
            return 0
        fi
    fi
    
    # For .tar files, assume they're valid (docker load will validate)
    if [[ "$file_path" == *.tar ]]; then
        return 0
    fi
    
    return 1
}

# Function to get XRd image name and tag from environment
get_xrd_image_info() {
    local base_image="${BASE_IMAGE:-xrd-control-plane}"
    local tag="${TAG_IMAGE:-latest}"
    
    echo "${base_image}:${tag}"
}

# Function to display format information
show_format_info() {
    local format="$1"
    local archive_path="$2"
    
    echo "XRd Archive Format Detection"
    echo "============================"
    echo "Archive: $(basename "$archive_path")"
    echo "Format: $format"
    echo ""
    
    case "$format" in
        "container")
            echo "This archive contains a Docker container that can be loaded directly."
            echo "Process: Archive -> docker load"
            ;;
        "nested")
            echo "This archive contains a nested structure with container files inside."
            echo "Process: Archive -> extract -> find container file -> docker load"
            ;;
        *)
            echo "Unknown format detected. Will attempt nested extraction method."
            ;;
    esac
    echo ""
}