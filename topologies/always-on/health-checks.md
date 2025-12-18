# Always-On Topology Health Checks

This document describes how to verify the health of the Always-On sandbox deployment using automated health check scripts.

## Overview

The Always-On topology includes comprehensive health check scripts that verify connectivity to all three XRd routers via multiple management interfaces:

- **NETCONF** - Port 830 on each node
- **gNMI** - Port 57777 on each node

## Quick Start

### Using Make (Recommended)

The simplest way to run health checks is using the Makefile:

```bash
# Set credentials (if different from defaults)
export XRD_USERNAME=testuser
export XRD_PASSWORD=testpassword

# Run health checks on all nodes
make health-check-always-on
```

Or pass credentials inline:

```bash
XRD_USERNAME=testuser XRD_PASSWORD=testpassword make health-check-always-on
```

### Using Scripts Directly

Navigate to the health checks directory and run:

```bash
cd scripts/deployment/always-on/health-checks

# Check all nodes with default credentials
./check-all-nodes.sh

# Or with custom credentials
./check-all-nodes.sh testuser testpassword

# Or using environment variables
export XRD_USERNAME=testuser
export XRD_PASSWORD=testpassword
./check-all-nodes.sh
```

## What Gets Checked

The health check script performs **6 total checks** across the topology:

| Node  | IP Address   | NETCONF (830) | gNMI (57777) |
| ----- | ------------ | ------------- | ------------ |
| xrd-1 | 10.10.20.101 | ✓             | ✓            |
| xrd-2 | 10.10.20.102 | ✓             | ✓            |
| xrd-3 | 10.10.20.103 | ✓             | ✓            |

Each check verifies:

- **NETCONF**: Successful connection and hello exchange
- **gNMI**: Server capabilities response

## Expected Output

### All Checks Passing

```text
════════════════════════════════════════════════════
   XRd Always-On Topology - Health Check Report
════════════════════════════════════════════════════

Checking 3 nodes × 2 protocols = 6 total checks
Timestamp: 2025-12-18 10:20:13

━━━ Checking xrd-1 (10.10.20.101) ━━━
  ✓ xrd-1 NETCONF: PASS
  ✓ xrd-1 gNMI: PASS

━━━ Checking xrd-2 (10.10.20.102) ━━━
  ✓ xrd-2 NETCONF: PASS
  ✓ xrd-2 gNMI: PASS

━━━ Checking xrd-3 (10.10.20.103) ━━━
  ✓ xrd-3 NETCONF: PASS
  ✓ xrd-3 gNMI: PASS

════════════════════════════════════════════════════
                    Summary
════════════════════════════════════════════════════

Total Checks:  6
Passed:        6
Failed:        0

✓ Overall Status: ALL SYSTEMS OPERATIONAL
```

### Some Checks Failing

If any checks fail, you'll see:

```text
✗ Overall Status: SOME SYSTEMS DOWN
Total Checks:  6
Passed:        4
Failed:        2
```

The script returns exit code `1` on failure, making it suitable for CI/CD integration.

## When to Run Health Checks

**Recommended scenarios:**

- ✅ After deploying the Always-On topology
- ✅ Before starting development work
- ✅ When troubleshooting connectivity issues
- ✅ After making configuration changes
- ✅ Before running automation scripts

**Not recommended:**

- ❌ Continuous/frequent monitoring (this is a shared sandbox)
- ❌ High-frequency automated polling (< 30 minutes)

## Prerequisites

The health check scripts require:

- **uv** - Python package manager (for NETCONF checks)
- **gnmic** - gNMI client tool (for gNMI checks)

Installation instructions are available in the [health checks README](../../scripts/deployment/always-on/health-checks/README.md#installation).

## Troubleshooting

### Authentication Failures

If you see authentication errors, verify you're using the correct credentials:

- Default: `cisco` / `C1sco12345`

### Connection Timeouts

If connections time out:

1. Verify containers are running: `make follow-always-on-logs`
2. Check port mappings in [docker-compose.yml](docker-compose.yml)
3. Verify network connectivity to the management IPs

### Individual Node/Protocol Testing

For targeted debugging, test specific protocols:

```bash
cd scripts/deployment/always-on/health-checks

# Test NETCONF on specific node
./netconf-healthcheck.sh 10.10.20.101 830 testuser testpassword

# Test gNMI on specific node
./gnmi-healthcheck.sh 10.10.20.101 57777 testuser testpassword
```

## Additional Documentation

For detailed information about:

- Authentication methods
- Script parameters and usage
- Installation procedures
- Advanced troubleshooting

See the [Health Checks README](../../scripts/deployment/always-on/health-checks/README.md).

## Integration with Deployment

**Note:** Due to the macvlan network driver configuration, health checks **cannot be run directly from the sandbox host**. Docker's macvlan driver isolates container networks from the host, preventing direct connectivity to the management IPs (10.10.20.101-103).

### Running Health Checks

To run health checks against this topology, you must execute them from:

- **An external machine** on the same network segment (10.10.20.0/24)
- **A management jump host** with access to the management network

Example from external machine:

```bash
# From a machine with network access to 10.10.20.0/24
cd scripts/deployment/always-on/health-checks
./check-all-nodes.sh testuser testpassword
```

### Deployment Workflow

The deployment Makefile targets focus on container provisioning:

```bash
make deploy-always-on    # Deploy containers and generate configs
make verify-always-on    # Verify deployment (container status only)
```

The `verify-always-on` step checks that containers are running but does **not** perform protocol-level health checks due to the macvlan network limitation.
