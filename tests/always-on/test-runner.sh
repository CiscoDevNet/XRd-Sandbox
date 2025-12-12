#!/usr/bin/env bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts/deployment/always-on"

# Test directories
INPUT_DIR="$TEST_DIR/input"
OUTPUT_DIR="$TEST_DIR/output"
EXPECTED_DIR="$TEST_DIR/expected"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Print functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Sync input files from real topology directory
sync_input_files() {
    print_info "Syncing input files from topology directory..."
    local TOPOLOGY_DIR="$REPO_ROOT/topologies/always-on"
    
    cp "$TOPOLOGY_DIR"/xrd-*-startup.cfg "$INPUT_DIR/" 2>/dev/null || {
        print_fail "Failed to copy startup config files from $TOPOLOGY_DIR"
        return 1
    }
    cp "$TOPOLOGY_DIR/aaa-config.cfg" "$INPUT_DIR/" 2>/dev/null || {
        print_fail "Failed to copy aaa-config.cfg from $TOPOLOGY_DIR"
        return 1
    }
    cp "$TOPOLOGY_DIR/fallback_local_user.cfg" "$INPUT_DIR/" 2>/dev/null || {
        print_fail "Failed to copy fallback_local_user.cfg from $TOPOLOGY_DIR"
        return 1
    }
    
    print_info "Successfully synced input files from real topology"
}

# Cleanup function
cleanup_output_dir() {
    print_info "Cleaning output directory..."
    rm -rf "$OUTPUT_DIR"/*
}

# Copy input files to output directory for testing
prepare_test_files() {
    print_info "Preparing test files..."
    # Copy base configs and create .deploy.cfg versions (simulating deploy.sh behavior)
    for cfg in "$INPUT_DIR"/xrd-*-startup.cfg; do
        if [[ -f "$cfg" ]]; then
            basename_cfg=$(basename "$cfg")
            # Copy to output as .deploy.cfg (what the injection scripts now expect)
            deploy_cfg="${basename_cfg%.cfg}.deploy.cfg"
            cp "$cfg" "$OUTPUT_DIR/$deploy_cfg"
        fi
    done
}

# Compare two files
compare_files() {
    local actual="$1"
    local expected="$2"
    local test_name="$3"
    
    (( TESTS_RUN += 1 ))
    
    if [[ ! -f "$actual" ]]; then
        print_fail "$test_name - Output file not found: $actual"
        (( TESTS_FAILED += 1 ))
        return 1
    fi
    
    if [[ ! -f "$expected" ]]; then
        print_fail "$test_name - Expected file not found: $expected"
        (( TESTS_FAILED += 1 ))
        return 1
    fi
    
    if diff -q "$actual" "$expected" > /dev/null 2>&1; then
        print_pass "$test_name"
        (( TESTS_PASSED += 1 ))
        return 0
    else
        print_fail "$test_name"
        echo "Differences found:"
        diff -u "$expected" "$actual" | head -20
        (( TESTS_FAILED += 1 ))
        return 1
    fi
}

# Test 1: TACACS configuration injection
test_tacacs_injection() {
    print_header "Test 1: TACACS Configuration Injection"
    
    cleanup_output_dir
    prepare_test_files
    
    print_test "Running inject-tacacs.sh script..."
    
    export TEST_MODE="$TEST_DIR"
    export TACACS_SERVER_IP="10.0.0.100"
    export TACACS_SECRET_KEY="testing123"
    
    if "$SCRIPTS_DIR/inject-tacacs.sh" > /dev/null 2>&1; then
        print_info "Script executed successfully"
    else
        print_fail "Script execution failed"
        return 1
    fi
    
    # Compare output for xrd-1
    compare_files "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" \
                  "$EXPECTED_DIR/xrd-1-startup-with-tacacs.cfg" \
                  "TACACS injection in xrd-1-startup.deploy.cfg"
    
    unset TEST_MODE TACACS_SERVER_IP TACACS_SECRET_KEY
}

# Test 2: AAA configuration injection
test_aaa_injection() {
    print_header "Test 2: AAA Configuration Injection"
    
    cleanup_output_dir
    prepare_test_files
    
    print_test "Running inject-aaa.sh script..."
    
    export TEST_MODE="$TEST_DIR"
    export TACACS_SERVER_IP="10.0.0.100"
    export TACACS_SECRET_KEY="testing123"
    
    if "$SCRIPTS_DIR/inject-aaa.sh" > /dev/null 2>&1; then
        print_info "Script executed successfully"
    else
        print_fail "Script execution failed"
        return 1
    fi
    
    # Compare output for xrd-1
    compare_files "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" \
                  "$EXPECTED_DIR/xrd-1-startup-with-aaa.cfg" \
                  "AAA injection in xrd-1-startup.deploy.cfg"
    
    unset TEST_MODE TACACS_SERVER_IP TACACS_SECRET_KEY
}

# Test 3: Local user configuration injection
test_local_user_injection() {
    print_header "Test 3: Local User Configuration Injection"
    
    cleanup_output_dir
    prepare_test_files
    
    print_test "Running inject-local-user.sh script..."
    
    export TEST_MODE="$TEST_DIR"
    
    if "$SCRIPTS_DIR/inject-local-user.sh" > /dev/null 2>&1; then
        print_info "Script executed successfully"
    else
        print_fail "Script execution failed"
        return 1
    fi
    
    # Compare output for xrd-1
    compare_files "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" \
                  "$EXPECTED_DIR/xrd-1-startup-with-local-user.cfg" \
                  "Local user injection in xrd-1-startup.deploy.cfg"
    
    unset TEST_MODE
}

# Test 4: All configurations combined (local user, then TACACS, then AAA)
test_combined_injection() {
    print_header "Test 4: Combined Configuration Injection (Local User + TACACS + AAA)"
    
    cleanup_output_dir
    prepare_test_files
    
    export TEST_MODE="$TEST_DIR"
    export TACACS_SERVER_IP="10.0.0.100"
    export TACACS_SECRET_KEY="testing123"
    
    print_test "Running inject-local-user.sh script..."
    if ! "$SCRIPTS_DIR/inject-local-user.sh" > /dev/null 2>&1; then
        print_fail "inject-local-user.sh execution failed"
        return 1
    fi
    
    print_test "Running inject-tacacs.sh script..."
    if ! "$SCRIPTS_DIR/inject-tacacs.sh" > /dev/null 2>&1; then
        print_fail "inject-tacacs.sh execution failed"
        return 1
    fi
    
    print_test "Running inject-aaa.sh script..."
    if ! "$SCRIPTS_DIR/inject-aaa.sh" > /dev/null 2>&1; then
        print_fail "inject-aaa.sh execution failed"
        return 1
    fi
    
    # Compare output for xrd-1
    compare_files "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" \
                  "$EXPECTED_DIR/xrd-1-startup-with-all.cfg" \
                  "Combined injection in xrd-1-startup.deploy.cfg"
    
    unset TEST_MODE TACACS_SERVER_IP TACACS_SECRET_KEY
}

# Test 5: Idempotency - Running scripts twice should not modify files
test_idempotency() {
    print_header "Test 5: Idempotency Check"
    
    cleanup_output_dir
    prepare_test_files
    
    export TEST_MODE="$TEST_DIR"
    export TACACS_SERVER_IP="10.0.0.100"
    export TACACS_SECRET_KEY="testing123"
    
    print_test "Running scripts first time..."
    "$SCRIPTS_DIR/inject-local-user.sh" > /dev/null 2>&1
    "$SCRIPTS_DIR/inject-tacacs.sh" > /dev/null 2>&1
    "$SCRIPTS_DIR/inject-aaa.sh" > /dev/null 2>&1
    
    # Create backup of first run
    cp "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" "$OUTPUT_DIR/xrd-1-startup.deploy.cfg.backup"
    
    print_test "Running scripts second time..."
    "$SCRIPTS_DIR/inject-local-user.sh" > /dev/null 2>&1
    "$SCRIPTS_DIR/inject-tacacs.sh" > /dev/null 2>&1
    "$SCRIPTS_DIR/inject-aaa.sh" > /dev/null 2>&1
    
    # Compare first and second run
    compare_files "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" \
                  "$OUTPUT_DIR/xrd-1-startup.deploy.cfg.backup" \
                  "Idempotency check - files should be identical"
    
    unset TEST_MODE TACACS_SERVER_IP TACACS_SECRET_KEY
}

# Test 6: Missing environment variables behavior
test_missing_env_vars() {
    print_header "Test 6: Missing Environment Variables"
    
    cleanup_output_dir
    prepare_test_files
    
    export TEST_MODE="$TEST_DIR"
    
    print_test "Running inject-tacacs.sh without TACACS env vars (should skip)..."
    if "$SCRIPTS_DIR/inject-tacacs.sh" > /dev/null 2>&1; then
        print_info "Script exited successfully (expected)"
        
        # Files should remain unchanged (base .cfg was copied to .deploy.cfg)
        compare_files "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" \
                      "$INPUT_DIR/xrd-1-startup.cfg" \
                      "File should be unchanged when TACACS vars missing"
    else
        print_fail "Script should exit gracefully when env vars missing"
    fi
    
    print_test "Running inject-aaa.sh without TACACS env vars (should skip)..."
    if "$SCRIPTS_DIR/inject-aaa.sh" > /dev/null 2>&1; then
        print_info "Script exited successfully (expected)"
        
        # Files should remain unchanged (base .cfg was copied to .deploy.cfg)
        compare_files "$OUTPUT_DIR/xrd-1-startup.deploy.cfg" \
                      "$INPUT_DIR/xrd-1-startup.cfg" \
                      "File should be unchanged when AAA vars missing"
    else
        print_fail "Script should exit gracefully when env vars missing"
    fi
    
    unset TEST_MODE
}

# Test 7: All three router configs are processed
test_multiple_routers() {
    print_header "Test 7: Multiple Router Configuration Files"
    
    cleanup_output_dir
    prepare_test_files
    
    export TEST_MODE="$TEST_DIR"
    
    print_test "Running inject-local-user.sh script..."
    if "$SCRIPTS_DIR/inject-local-user.sh" > /dev/null 2>&1; then
        print_info "Script executed successfully"
    else
        print_fail "Script execution failed"
        return 1
    fi
    
    # Check that all three files have the local user config
    for router in xrd-1 xrd-2 xrd-3; do
        (( TESTS_RUN += 1 ))
        if grep -q "username cisco" "$OUTPUT_DIR/${router}-startup.deploy.cfg" && \
           grep -q "group root-lr" "$OUTPUT_DIR/${router}-startup.deploy.cfg" && \
           grep -q "group cisco-support" "$OUTPUT_DIR/${router}-startup.deploy.cfg"; then
            print_pass "Local user injected into ${router}-startup.deploy.cfg"
            (( TESTS_PASSED += 1 ))
        else
            print_fail "Local user NOT found in ${router}-startup.deploy.cfg"
            (( TESTS_FAILED += 1 ))
        fi
    done
    
    unset TEST_MODE
}

# Main test execution
main() {
    print_header "Always-On Scripts Test Suite"
    echo "Test directory: $TEST_DIR"
    echo "Scripts directory: $SCRIPTS_DIR"
    echo ""
    
    # Validate test structure
    if [[ ! -d "$INPUT_DIR" ]] || [[ ! -d "$OUTPUT_DIR" ]] || [[ ! -d "$EXPECTED_DIR" ]]; then
        echo "ERROR: Test directory structure is incomplete"
        echo "Expected directories: input/, output/, expected/"
        exit 1
    fi
    
    # Sync input files from real topology (unless FREEZE_INPUTS is set)
    if [[ -z "${FREEZE_INPUTS:-}" ]]; then
        print_info "Syncing test inputs from real topology files..."
        if ! sync_input_files; then
            echo "ERROR: Failed to sync input files"
            exit 1
        fi
        echo ""
    else
        print_info "FREEZE_INPUTS set - using existing input files"
        echo ""
    fi
    
    # Run all tests
    test_tacacs_injection
    echo ""
    
    test_aaa_injection
    echo ""
    
    test_local_user_injection
    echo ""
    
    test_combined_injection
    echo ""
    
    test_idempotency
    echo ""
    
    test_missing_env_vars
    echo ""
    
    test_multiple_routers
    echo ""
    
    # Print summary
    print_header "Test Summary"
    echo "Total tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        print_pass "All tests passed! ✓"
        exit 0
    else
        echo ""
        print_fail "Some tests failed!"
        exit 1
    fi
}

# Run main function
main
