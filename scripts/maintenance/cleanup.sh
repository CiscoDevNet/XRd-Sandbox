#!/usr/bin/env bash

# Cleanup Environment Script for XRd Sandbox
# 
# This script removes temporary files and directories created during XRd Sandbox setup.
# It is designed to be used in CI/CD pipelines and provides clear logging and error handling.
#
# Files and directories cleaned up:
# - xrd-container/ directory (extracted container files)
# - XRd container archive files (.tgz files for both x64 and x86 architectures)
#
# Usage:
# - Direct execution: ./scripts/maintenance/cleanup.sh
# - Via Makefile: make cleanup-environment
# - CI/CD Integration: The script provides detailed status output suitable for automated systems
#
# Exit codes:
# 0 = Success (cleanup completed successfully)
# 1 = Error (failed to cleanup one or more items)
#
# CI/CD Features:
# - Detailed logging with clear status messages
# - Verification step to ensure cleanup was successful  
# - Fallback behavior when environment variables are not available
# - Error accumulation and summary reporting
# - Clear success/failure indication for pipeline integration

set -uo pipefail

# Source common utilities for consistent logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# Initialize logging
init_logging "cleanup-environment"

# Initialize cleanup status tracking
CLEANUP_SUCCESS=true
CLEANUP_ERRORS=()

# Function to safely remove a file or directory with logging
safe_remove() {
    local target="$1"
    local description="$2"
    
    if [[ ! -e "$target" ]]; then
        print_info "$description not found, skipping: $target"
        return 0
    fi
    
    print_info "Removing $description: $target"
    
    if rm -rf "$target" 2>/dev/null; then
        print_success "Successfully removed $description"
        return 0
    else
        local error_msg="Failed to remove $description: $target"
        print_error "$error_msg"
        CLEANUP_ERRORS+=("$error_msg")
        CLEANUP_SUCCESS=false
        return 1
    fi
}

# Function to cleanup XRd container directory
cleanup_xrd_container_directory() {
    local sandbox_root
    sandbox_root="$(get_sandbox_root)"
    local xrd_container_dir="$sandbox_root/xrd-container"
    
    print_info "Cleaning up XRd container directory..."
    safe_remove "$xrd_container_dir" "XRd container directory"
}

# Function to cleanup XRd container archive files
cleanup_xrd_container_archives() {
    local sandbox_root
    sandbox_root="$(get_sandbox_root)"
    
    print_info "Cleaning up XRd container archive files..."
    
    # Try to load environment variables to get version information
    set +eu  # Temporarily disable exit on error and unset variable checking
    load_sandbox_env "$sandbox_root" >/dev/null 2>&1
    local env_load_success=$?
    set -u   # Re-enable unset variable checking
    
    if [[ $env_load_success -ne 0 ]] || [[ -z "${XRD_CONTAINER_VERSION:-}" ]]; then
        print_warning "Could not load environment variables or version not found, will search for all .tgz files"
        cleanup_all_tgz_files "$sandbox_root"
        return
    fi
    
    print_info "Using XRD_CONTAINER_VERSION: $XRD_CONTAINER_VERSION"
    
    # Cleanup specific XRd archive files based on version
    local x64_archive="$sandbox_root/xrd-control-plane-container-x64.${XRD_CONTAINER_VERSION}.tgz"
    local x86_archive="$sandbox_root/xrd-control-plane-container-x86.${XRD_CONTAINER_VERSION}.tgz"
    
    safe_remove "$x64_archive" "XRd x64 container archive"
    safe_remove "$x86_archive" "XRd x86 container archive"
    
    # Also check for the environment variable defined archive
    if [[ -n "${XRD_CONTAINER_ARCHIVE:-}" ]]; then
        local env_archive="$sandbox_root/$XRD_CONTAINER_ARCHIVE"
        safe_remove "$env_archive" "XRd container archive (from env var)"
    fi
}

# Function to cleanup all .tgz files (fallback method)
cleanup_all_tgz_files() {
    local sandbox_root="$1"
    
    print_info "Searching for all .tgz files in sandbox root..."
    
    # Find all .tgz files in the sandbox root directory (not subdirectories)
    local tgz_files
    mapfile -t tgz_files < <(find "$sandbox_root" -maxdepth 1 -name "*.tgz" -type f 2>/dev/null || true)
    
    if [[ ${#tgz_files[@]} -eq 0 ]]; then
        print_info "No .tgz files found in sandbox root directory"
        return 0
    fi
    
    print_info "Found ${#tgz_files[@]} .tgz file(s) to remove"
    
    for tgz_file in "${tgz_files[@]}"; do
        local filename
        filename="$(basename "$tgz_file")"
        safe_remove "$tgz_file" "archive file ($filename)"
    done
}

# Function to verify cleanup completion
verify_cleanup() {
    local sandbox_root
    sandbox_root="$(get_sandbox_root)"
    
    print_info "Verifying cleanup completion..."
    
    local verification_errors=()
    
    # Check if xrd-container directory still exists
    if [[ -d "$sandbox_root/xrd-container" ]]; then
        verification_errors+=("xrd-container directory still exists")
    fi
    
    # Check for remaining .tgz files
    local remaining_tgz
    mapfile -t remaining_tgz < <(find "$sandbox_root" -maxdepth 1 -name "*.tgz" -type f 2>/dev/null || true)
    
    if [[ ${#remaining_tgz[@]} -gt 0 ]]; then
        verification_errors+=("${#remaining_tgz[@]} .tgz file(s) still exist: ${remaining_tgz[*]}")
    fi
    
    if [[ ${#verification_errors[@]} -gt 0 ]]; then
        print_error "Cleanup verification failed:"
        for error in "${verification_errors[@]}"; do
            print_error "  - $error"
        done
        CLEANUP_SUCCESS=false
        return 1
    fi
    
    print_success "Cleanup verification passed - all target files and directories removed"
    return 0
}

# Function to print cleanup summary
print_cleanup_summary() {
    echo
    print_info "=== Cleanup Summary ==="
    
    if [[ "$CLEANUP_SUCCESS" == true ]]; then
        print_success "Environment cleanup completed successfully"
        print_info "All temporary files and directories have been removed"
        echo
        print_info "CI/CD Pipeline Status: SUCCESS"
        return 0
    else
        print_error "Environment cleanup completed with errors"
        
        if [[ ${#CLEANUP_ERRORS[@]} -gt 0 ]]; then
            print_error "Errors encountered:"
            for error in "${CLEANUP_ERRORS[@]}"; do
                print_error "  - $error"
            done
        fi
        
        echo
        print_error "CI/CD Pipeline Status: FAILED"
        print_info "Manual intervention may be required to complete cleanup"
        return 1
    fi
}

# Main execution function
main() {
    print_info "=== Starting XRd Sandbox Environment Cleanup ==="
    print_info "Target directory: $(get_sandbox_root)"
    echo
    
    # Perform cleanup operations
    cleanup_xrd_container_directory
    echo
    
    cleanup_xrd_container_archives
    echo
    
    # Verify cleanup was successful
    verify_cleanup
    echo
    
    # Print summary and exit with appropriate code
    if print_cleanup_summary; then
        log_message "[SUCCESS] Cleanup completed successfully"
        finalize_logging
        exit 0
    else
        log_message "[ERROR] Cleanup completed with errors"
        finalize_logging
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi