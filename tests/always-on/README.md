# Always-On Scripts Test Suite

This directory contains comprehensive tests for the always-on injection scripts that manage TACACS, AAA, and local user configurations.

## Directory Structure

```
tests/always-on/
├── input/              # Auto-synced from topologies/always-on/ before each test run
│   ├── xrd-1-startup.cfg        (synced from real topology)
│   ├── xrd-2-startup.cfg        (synced from real topology)
│   ├── xrd-3-startup.cfg        (synced from real topology)
│   ├── aaa-config.cfg           (synced from real topology)
│   └── fallback_local_user.cfg  (synced from real topology)
├── output/             # Working directory for test runs (modified during tests)
│   └── (files copied from input and modified by scripts)
├── expected/           # Expected output files for validation
│   ├── xrd-1-startup-with-tacacs.cfg
│   ├── xrd-1-startup-with-aaa.cfg
│   ├── xrd-1-startup-with-local-user.cfg
│   └── xrd-1-startup-with-all.cfg
└── test-runner.sh      # Main test execution script
```

**Important:** Input files are automatically synced from `topologies/always-on/` before each test run. This ensures tests always validate scripts against the **actual production configuration files**.

## Running Tests

### Using Make (Recommended)

```bash
make test-always-on
```

This will:

1. Sync latest configuration files from `topologies/always-on/`
2. Run all test scenarios
3. Report results

### Freezing Input Files (Optional)

To run tests with existing input files without syncing (useful for debugging):

```bash
FREEZE_INPUTS=1 make test-always-on
```

### Direct Execution

```bash
./tests/always-on/test-runner.sh
```

## Test Coverage

The test suite includes the following test scenarios:

### 1. TACACS Configuration Injection

- **Purpose**: Validates that TACACS server configuration is correctly injected
- **Environment Variables**: `TACACS_SERVER_IP`, `TACACS_SECRET_KEY`
- **Expected Behavior**: TACACS configuration block added at the beginning of startup files

### 2. AAA Configuration Injection

- **Purpose**: Validates that AAA authentication/authorization configuration is correctly injected
- **Environment Variables**: `TACACS_SERVER_IP`, `TACACS_SECRET_KEY`
- **Expected Behavior**: AAA configuration block added at the beginning of startup files

### 3. Local User Configuration Injection

- **Purpose**: Validates that fallback local user is correctly injected
- **Environment Variables**: None (uses default config from `fallback_local_user.cfg`)
- **Expected Behavior**: Local user configuration block added at the beginning of startup files

### 4. Combined Configuration Injection

- **Purpose**: Validates that all three configurations work together correctly
- **Execution Order**: Local User → TACACS → AAA
- **Expected Behavior**: All three configuration blocks present in correct order

### 5. Idempotency Check

- **Purpose**: Ensures scripts don't modify files if configuration already exists
- **Expected Behavior**: Running scripts multiple times produces identical results

### 6. Missing Environment Variables

- **Purpose**: Validates graceful handling when required env vars are not set
- **Expected Behavior**: Scripts exit successfully without modifying files

### 7. Multiple Router Configuration Files

- **Purpose**: Ensures all router configuration files are processed
- **Expected Behavior**: Configuration injected into all xrd-\*-startup.cfg files

## How It Works

### TEST_MODE Environment Variable

The injection scripts have been refactored to support a `TEST_MODE` environment variable:

- **When TEST_MODE is set**: Scripts use test directories
  - Input configs: `$TEST_MODE/input/`
  - Output configs: `$TEST_MODE/output/`
- **When TEST_MODE is not set**: Scripts use production directories (default behavior)
  - Input/Output configs: `$SANDBOX_ROOT/topologies/always-on/`

This approach ensures:

- ✅ No changes to Makefile targets
- ✅ No script parameters needed
- ✅ Production behavior unchanged
- ✅ Clean separation between test and production

### Test Execution Flow

1. **Setup**: Copy baseline configs from `input/` to `output/`
2. **Execute**: Run injection scripts with `TEST_MODE` set
3. **Validate**: Compare `output/` files against `expected/` files
4. **Cleanup**: Clear `output/` directory for next test

## Interpreting Results

The test runner provides color-coded output:

- 🟢 **Green [PASS]**: Test passed successfully
- 🔴 **Red [FAIL]**: Test failed, differences shown
- 🟡 **Yellow [TEST]**: Test starting
- 🔵 **Blue [INFO]**: Informational message

### Example Output

```
========================================
Test 1: TACACS Configuration Injection
========================================
[INFO] Cleaning output directory...
[INFO] Preparing test files...
[TEST] Running inject-tacacs.sh script...
[INFO] Script executed successfully
[PASS] TACACS injection in xrd-1-startup.cfg

========================================
Test Summary
========================================
Total tests run: 10
Tests passed: 10
Tests failed: 0

[PASS] All tests passed! ✓
```

## Maintaining Tests

### Adding New Tests

1. Add test function to `test-runner.sh`:

   ```bash
   test_new_feature() {
       print_header "Test N: New Feature"
       cleanup_output_dir
       prepare_test_files

       # Test logic here

       compare_files "$OUTPUT_DIR/file.cfg" \
                     "$EXPECTED_DIR/expected-file.cfg" \
                     "Test description"
   }
   ```

2. Call the function in `main()`:
   ```bash
   test_new_feature
   echo ""
   ```

### Updating Expected Outputs

If scripts are intentionally modified:

1. Run scripts manually with desired configuration
2. Verify output is correct
3. Copy output to `expected/` directory
4. Update test assertions if needed

### Test Data

Input files should match the baseline configuration from `topologies/always-on/`:

- Keep `input/` files in sync with production configs
- Update when topology configurations change
- Maintain consistency across test scenarios

## Integration with CI/CD

These tests can be integrated into CI/CD pipelines:

```bash
# Exit code 0 on success, 1 on failure
make test-always-on
```

## Troubleshooting

### Tests Failing After Script Changes

1. Verify scripts still accept `TEST_MODE` environment variable
2. Check that scripts use correct paths when `TEST_MODE` is set
3. Ensure scripts maintain backward compatibility

### Differences in Output

1. Check for whitespace differences (extra spaces, tabs vs spaces)
2. Verify expected files match actual script behavior
3. Use `diff -u` output to identify specific changes

### Permission Issues

```bash
chmod +x tests/always-on/test-runner.sh
chmod +x scripts/deployment/always-on/*.sh
```

## Best Practices

1. **Run tests before committing**: Ensure changes don't break existing functionality
2. **Update tests with script changes**: Keep tests in sync with implementation
3. **Add tests for new features**: Maintain comprehensive coverage
4. **Keep test data current**: Update input files when topology configs change
5. **Document test failures**: If tests fail, investigate before updating expected outputs

## Related Documentation

- [Always-On Deployment](../../topologies/always-on/deployment.md)
- [Always-On README](../../topologies/always-on/README.md)
- [Contributing Guidelines](../../CONTRIBUTING.md)
