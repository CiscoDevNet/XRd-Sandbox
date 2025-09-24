# XRd Sandbox Scripts

This directory contains all the scripts needed to set up, deploy, and manage XRd sandbox environments. The scripts are organized in a hierarchical structure for better organization and maintainability.

## Directory Structure

```
scripts/
├── README.md                    # This file - documentation for the scripts directory
├── setup/                       # Setup and installation scripts
│   ├── configure-ssh.sh        # Configure SSH keys for Git operations
│   ├── install-xrd-tools.sh    # Install and configure xrd-tools repository
│   ├── extract-container.sh    # Extract XRd container archive
│   └── load-container.sh       # Load XRd container into Docker/Podman
├── validation/                  # Environment validation scripts
│   └── environment.sh          # Validate environment prerequisites
├── deployment/                  # Topology deployment scripts
│   └── segment-routing.sh      # Deploy segment routing topology
├── maintenance/                 # Cleanup and maintenance scripts
│   └── cleanup.sh              # Clean up environment after setup
├── lib/                        # Shared utility libraries
│   ├── common.sh               # Common utilities and functions
│   └── container-format.sh     # XRd container format detection utilities
└── examples/                   # Example scripts and documentation
    └── utility-usage.sh        # Example showing how to use common utilities
```

## Script Categories

### Setup Scripts (`setup/`)

Scripts for initial setup and installation of components:

- **configure-ssh.sh**: Sets up SSH keys for Git operations
- **install-xrd-tools.sh**: Clones and configures the xrd-tools repository
- **extract-container.sh**: Extracts XRd container archive files
- **load-container.sh**: Loads XRd container images into Docker/Podman

### Validation Scripts (`validation/`)

Scripts for validating environment and prerequisites:

- **environment.sh**: Comprehensive environment validation for XRd sandbox

### Deployment Scripts (`deployment/`)

Scripts for deploying specific topologies and services:

- **segment-routing.sh**: Deploys the segment routing sandbox topology

### Maintenance Scripts (`maintenance/`)

Scripts for cleanup and maintenance tasks:

- **cleanup.sh**: Cleans up temporary files and containers after setup

### Library Scripts (`lib/`)

Shared utility libraries used by other scripts:

- **common.sh**: Common utilities, logging functions, and environment handling
- **container-format.sh**: XRd container format detection and handling utilities

### Examples (`examples/`)

Example scripts and documentation:

- **utility-usage.sh**: Demonstrates how to use the common utilities library

## Usage

### Via Makefile (Recommended)

Most scripts are designed to be used through the Makefile targets:

```bash
make setup-ssh                   # Run setup/configure-ssh.sh
make clone-xrd-tools             # Run setup/install-xrd-tools.sh
make validate-environment        # Run validation/environment.sh
make deploy-segment-routing      # Run deployment/segment-routing.sh
make extract-xrd                 # Run setup/extract-container.sh
make load-xrd                    # Run setup/load-container.sh
make cleanup-environment         # Run maintenance/cleanup.sh
```

### Direct Execution

Scripts can also be run directly:

```bash
./scripts/setup/configure-ssh.sh
./scripts/validation/environment.sh
./scripts/deployment/segment-routing.sh
```

## Dependencies

- All operational scripts depend on `lib/common.sh`
- Container-related scripts also depend on `lib/container-format.sh`
- Scripts automatically source their dependencies using relative paths

## Development

When creating new scripts:

1. Place them in the appropriate category directory
2. Source `../lib/common.sh` for common utilities
3. Follow the established error handling and logging patterns
4. Update this README and the Makefile if adding new functionality

## Migration Notes

This structure replaces the previous flat directory layout:

- `common_utils.sh` → `lib/common.sh`
- `xrd-format-utils.sh` → `lib/container-format.sh`
- `clone-xrd-tools.sh` → `setup/install-xrd-tools.sh`
- `setup_ssh.sh` → `setup/configure-ssh.sh`
- `extract-xrd-container.sh` → `setup/extract-container.sh`
- `load-xrd-container.sh` → `setup/load-container.sh`
- `validate-environment.sh` → `validation/environment.sh`
- `deploy-segment-routing.sh` → `deployment/segment-routing.sh`
- `cleanup-environment.sh` → `maintenance/cleanup.sh`
- `example_using_utils.sh` → `examples/utility-usage.sh`

All script cross-references and Makefile targets have been updated accordingly.
