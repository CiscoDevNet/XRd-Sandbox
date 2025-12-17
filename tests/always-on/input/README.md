# Test Input Files

This directory contains input files for testing. Files are **automatically synced** from the real topology directory before each test run.

## How It Works

When you run `make test-always-on`, the test runner automatically copies the latest versions of:

- `topologies/always-on/xrd-*-startup.cfg`
- `topologies/always-on/aaa-config.cfg`
- `topologies/always-on/fallback_local_user.cfg`

This ensures tests always run against the **actual production configuration files**.

## Freezing Inputs (Optional)

If you need to run tests with frozen input files (for debugging or reproducibility):

```bash
FREEZE_INPUTS=1 make test-always-on
```

This skips the sync step and uses whatever files are currently in this directory.

## Why This Approach?

✅ Tests validate scripts work with **real topology files**  
✅ Catches breaking changes when topology is modified  
✅ No manual sync required - always up to date  
✅ Simple and reliable
