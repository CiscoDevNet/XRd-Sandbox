# Logging System Implementation Summary

## What Was Implemented

A comprehensive, production-ready logging system for the XRd Sandbox project that addresses all your requirements:

### 1. **Session-Based Logging Structure**

- Logs organized by execution timestamp: `logs/YYYY-MM-DD_HH-MM-SS/`
- All nested makefile steps share the same RUN_ID
- Each script gets its own log file within the session directory

### 2. **Intelligent Color Management**

- **Default**: Colors disabled (ENABLE_COLOR=0) for CI/CD compatibility
- **TTY Detection**: Automatically enables colors when running interactively in terminal
- **Development Override**: Set ENABLE_COLOR=1 for VS Code development
- **Automatic Stripping**: Color codes never written to log files

### 3. **Automatic Log Management**

- RUN_ID generated once per `make` invocation in Makefile
- Shared across all sub-scripts and nested targets
- Log directory auto-created before any script runs

## Files Modified

1. **sandbox_env_vars.sh**

   - Added `ENABLE_COLOR` variable (default: 0)
   - Added `LOG_DIR` variable
   - Added `RUN_ID` variable
   - Documented logging configuration

2. **scripts/lib/common.sh**

   - Added TTY detection function (`should_use_colors`)
   - Made color variables conditional based on environment
   - Added `init_logging()` - Initialize script logging
   - Added `log_message()` - Write to log file (strips colors)
   - Added `log_exec()` - Execute command with automatic logging
   - Added `finalize_logging()` - Close log and show path
   - Exported new functions for use in all scripts

3. **Makefile**

   - Added RUN_ID generation (one timestamp per make invocation)
   - Added automatic log directory creation
   - Exports RUN_ID to all sub-scripts

4. **.gitignore**

   - Added `logs/` directory to prevent committing logs

5. **scripts/deployment/segment-routing.sh** (Example)
   - Updated to demonstrate logging usage
   - Shows proper init, logging, and finalization

## Documentation Created

1. **docs/LOGGING.md** - Comprehensive guide

   - Overview and features
   - Configuration details
   - Usage instructions and examples
   - Migration guide for existing scripts
   - Troubleshooting section
   - Best practices

2. **docs/LOGGING-QUICK-REFERENCE.md** - Quick reference
   - Common commands and patterns
   - Environment variables table
   - Function reference
   - CI/CD examples

## How It Works

### Color Control Decision Tree

```
Is ENABLE_COLOR=1?
├─ Yes → Use colors
└─ No → Is stdout a TTY?
    ├─ Yes → Use colors (interactive terminal)
    └─ No → No colors (piped to file/CI)
```

### Log File Lifecycle

```
make deploy-always-on
  ├─ Makefile generates RUN_ID: 2025-12-18_14-30-45
  ├─ Creates: logs/2025-12-18_14-30-45/
  │
  ├─ create-configs.sh
  │   ├─ init_logging "create-configs"
  │   ├─ Creates: logs/2025-12-18_14-30-45/create-configs.log
  │   ├─ Executes script with logging
  │   └─ finalize_logging
  │
  ├─ inject-aaa.sh
  │   ├─ init_logging "inject-aaa"
  │   ├─ Uses same RUN_ID: 2025-12-18_14-30-45
  │   ├─ Creates: logs/2025-12-18_14-30-45/inject-aaa.log
  │   └─ finalize_logging
  │
  └─ ... (all other scripts use same RUN_ID)
```

## Usage Examples

### For Development (VS Code)

```bash
# Enable colors for better readability
export ENABLE_COLOR=1
make deploy-segment-routing

# Colors automatically work in terminal
# Logs still clean (no color codes)
```

### For CI/CD (Ansible/Jenkins/GitLab)

```bash
# Colors automatically disabled
make deploy-always-on

# Logs are clean and parseable
# Each run gets unique timestamp directory
```

### Viewing Logs

```bash
# List all sessions
ls -la logs/

# View latest session
ls -la logs/$(ls -t logs/ | head -1)/

# Read a specific log
cat logs/2025-12-18_14-30-45/segment-routing-deploy.log

# Follow logs in real-time (while script runs)
tail -f logs/2025-12-18_14-30-45/create-configs.log
```

## Key Benefits

1. **Zero Configuration Required**

   - Works out of the box with sensible defaults
   - Automatically adapts to environment (TTY vs non-TTY)

2. **Development-Friendly**

   - Colors available when needed (VS Code terminal)
   - Easy to enable/disable with one environment variable

3. **CI/CD Ready**

   - No color codes in CI/CD pipelines by default
   - Clean, parseable log files
   - Structured directory layout

4. **Session Grouping**

   - All related operations in one timestamped directory
   - Easy to correlate logs from multi-step deployments
   - Simple cleanup (delete old directories)

5. **Backward Compatible**
   - Existing scripts continue to work
   - New logging features optional
   - Gradual migration possible

## Next Steps

### To Use Logging in Other Scripts

1. Add at start of script (after sourcing common.sh):

   ```bash
   init_logging "script-name"
   ```

2. Replace `run_command` with `log_exec`:

   ```bash
   log_exec "Description" command args
   ```

3. Add before exit points:
   ```bash
   finalize_logging
   ```

### Recommended Scripts to Update Next

- `scripts/deployment/always-on/*.sh` - All always-on scripts
- `scripts/setup/*.sh` - Setup scripts
- `scripts/validation/*.sh` - Validation scripts

See [segment-routing.sh](../scripts/deployment/segment-routing.sh) for a complete example.

## Industry Standard Practices Used

This implementation follows best practices from major projects:

1. **Session-based logging** (similar to Jenkins, GitLab CI)
2. **TTY detection** (similar to npm, cargo, git)
3. **Color control via env var** (NO_COLOR standard, but inverted for backward compatibility)
4. **Structured log directories** (similar to build systems like Maven, Gradle)
5. **ANSI code stripping** (standard practice in logging libraries)

## Questions?

- See [docs/LOGGING.md](LOGGING.md) for comprehensive documentation
- See [docs/LOGGING-QUICK-REFERENCE.md](LOGGING-QUICK-REFERENCE.md) for quick reference
- Check [scripts/deployment/segment-routing.sh](../scripts/deployment/segment-routing.sh) for example implementation
