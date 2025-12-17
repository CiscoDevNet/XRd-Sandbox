# Always-On Scripts Test Suite

Comprehensive tests for the always-on injection scripts (TACACS, AAA, and local user configurations).

## Quick Start

```bash
# Run all tests
make test-always-on

# Skip syncing input files (useful for debugging)
FREEZE_INPUTS=1 make test-always-on
```

## Directory Structure

```text
tests/always-on/
├── input/      # Auto-synced from topologies/always-on/ before each test
├── output/     # Working directory (modified during tests)
├── expected/   # Expected output files for validation
└── test-runner.sh
```

Input files are automatically synced from `topologies/always-on/` to ensure tests validate against actual production configurations.

## Test Coverage (10 tests)

1. **TACACS Injection** - Validates TACACS server configuration injection
2. **AAA Injection** - Validates AAA authentication/authorization configuration
3. **Local User Injection** - Validates fallback local user injection
4. **Combined Injection** - All three configurations together (Local User → TACACS → AAA)
5. **Idempotency** - Scripts don't modify files if config already exists
6. **Missing Env Vars** - Graceful handling when environment variables not set
7. **Multiple Routers** - All xrd-\*-startup.cfg files processed correctly

## How It Works

Scripts support `TEST_MODE` environment variable:

- **When set**: Uses `$TEST_MODE/input/` and `$TEST_MODE/output/`
- **When not set**: Uses production paths in `$SANDBOX_ROOT/topologies/always-on/`

**Test Flow**: Setup → Execute with TEST_MODE → Validate → Cleanup

## Output

Color-coded results: 🟢 [PASS] | 🔴 [FAIL] | 🟡 [TEST] | 🔵 [INFO]

```text
Test Summary: 10 run | 10 passed | 0 failed
[PASS] All tests passed! ✓
```

## Maintenance

### Adding New Tests

1. Add test function to `test-runner.sh`
2. Create expected output files if needed
3. Call function in `main()`

### Updating Expected Outputs

When scripts are intentionally modified:

1. Run scripts manually and verify output
2. Copy verified output to `expected/` directory

### CI/CD Integration

```bash
make test-always-on  # Exit code 0 on success, 1 on failure
```

## Troubleshooting

**Tests failing after script changes?**

- Verify `TEST_MODE` support still present
- Check scripts use correct paths when `TEST_MODE` is set

**Output differences?**

- Check for whitespace differences (spaces vs tabs)
- Review `diff -u` output for specific changes

**Permission issues?**

```bash
chmod +x tests/always-on/test-runner.sh scripts/deployment/always-on/*.sh
```

## Design Rationale

**Why TEST_MODE environment variable?**

- No script parameters needed
- No Makefile changes to existing targets
- Clean separation between test and production
- Production behavior unchanged

**Why this directory structure?**

- `input/`: Immutable baseline (synced from production)
- `output/`: Working directory (cleaned each test)
- `expected/`: Verified correct outputs

## Modified Files

Scripts with TEST_MODE support:

- `scripts/deployment/always-on/inject-local-user.sh`
- `scripts/deployment/always-on/inject-aaa.sh`
- `scripts/deployment/always-on/inject-tacacs.sh`

Makefile: Added `test-always-on` target
