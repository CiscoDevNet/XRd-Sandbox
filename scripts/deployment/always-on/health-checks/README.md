# Health Check Scripts

This directory contains health check scripts for verifying connectivity to XRd routers via different management interfaces.

## Authentication

All scripts support flexible authentication through:

1. **Environment Variables** (recommended for automation):

   - `XRD_USERNAME` - Username for authentication
   - `XRD_PASSWORD` - Password for authentication

2. **Command-line Arguments**: Pass credentials directly as script parameters

3. **Default Credentials**: `cisco` / `C1sco12345`

**Priority order:** Command-line arguments > Environment variables > Defaults

### Setting Environment Variables

```bash
# Export for current session
export XRD_USERNAME=myuser
export XRD_PASSWORD=mypassword

# Now run any health check script
./netconf-healthcheck.sh
./gnmi-healthcheck.sh
./check-all-nodes.sh
```

---

## Available Scripts

### 1. NETCONF Health Check (`netconf-healthcheck.sh`)

Verifies NETCONF connectivity by establishing a session and checking the hello exchange. Supports both IP addresses and hostnames (hostnames are automatically resolved to IPs using Python's socket module).

**Prerequisites:**

- `uv` package manager must be installed
- `ncclient` Python library (automatically installed via uv)

**Usage:**

```bash
./netconf-healthcheck.sh [host] [port] [username] [password]
```

**Default values:**

- Host: `10.10.20.101`
- Port: `830`
- Username: `cisco` (or `$XRD_USERNAME`)
- Password: `C1sco12345` (or `$XRD_PASSWORD`)

**Examples:**

```bash
# Use default values
./netconf-healthcheck.sh

# Use environment variables
export XRD_USERNAME="admin"
export XRD_PASSWORD="secret"
./netconf-healthcheck.sh

# Specify custom host (use env vars for credentials)
./netconf-healthcheck.sh 192.168.1.100

# Use hostname instead of IP
./netconf-healthcheck.sh router1.example.com

# Specify all parameters (override everything)
./netconf-healthcheck.sh 192.168.1.100 830 admin mypassword
```

**Success output:**

```
✓ SUCCESS: NETCONF is working!
```

**Failure output:**

```
✗ FAILED: NETCONF connection failed!
```

**Note:** The script automatically resolves hostnames to IP addresses since ncclient requires IPs. If hostname resolution fails, the script will exit with an error message.

---

### 2. gNMI Health Check (`gnmi-healthcheck.sh`)

Verifies gNMI connectivity by checking server capabilities. Supports both IP addresses and hostnames natively (gnmic can handle both).

**Prerequisites:**

- `gnmic` tool must be installed

**Usage:**

```bash
./gnmi-healthcheck.sh [host] [port] [username] [password]
```

**Default values:**

- Host: `10.10.20.101`
- Port: `57777`
- Username: `cisco` (or `$XRD_USERNAME`)
- Password: `C1sco12345` (or `$XRD_PASSWORD`)

**Examples:**

```bash
# Use default values
./gnmi-healthcheck.sh

# Use environment variables
export XRD_USERNAME=admin
export XRD_PASSWORD=secret
./gnmi-healthcheck.sh

# Specify custom host and port (use env vars for credentials)
./gnmi-healthcheck.sh 192.168.1.100 57400

# Use hostname instead of IP
./gnmi-healthcheck.sh router1.example.com 57777

# Specify all parameters (override everything)
./gnmi-healthcheck.sh 192.168.1.100 57400 admin mypassword
```

**Success output:**

```
✓ SUCCESS: gNMI is working!
```

**Failure output:**

```
✗ FAILED: gNMI connection failed!
```

**Note:** gnmic natively supports hostnames, so no resolution is needed. However, DNS must be properly configured for hostname resolution to work.

---

### 3. All Nodes Health Check (`check-all-nodes.sh`)

Performs comprehensive health checks on XRd routers. Tests both NETCONF and gNMI connectivity for each node. By default, checks the three routers in the always-on topology, but can be configured to check any list of IPs.

**Prerequisites:**

- `uv` package manager (for NETCONF checks)
- `gnmic` tool (for gNMI checks)

**Usage:**

```bash
./check-all-nodes.sh [username] [password] [ip1] [ip2] [ip3] ...
```

**Default values:**

- Username: `cisco` (or `$XRD_USERNAME`)
- Password: `C1sco12345` (or `$XRD_PASSWORD`)
- IPs: `10.10.20.101,10.10.20.102,10.10.20.103` (or `$XRD_IPS`)

**Environment Variables:**

- `XRD_USERNAME` - Username for authentication
- `XRD_PASSWORD` - Password for authentication
- `XRD_IPS` - Comma-separated list of IP addresses to check

**Examples:**

```bash
# Use all defaults (checks 10.10.20.101, 10.10.20.102, 10.10.20.103)
./check-all-nodes.sh

# Use environment variables for credentials
export XRD_USERNAME=admin
export XRD_PASSWORD=secret
./check-all-nodes.sh

# Specify custom credentials (override env vars)
./check-all-nodes.sh myuser mypassword

# Check custom IPs via environment variable
export XRD_IPS="192.168.1.1,192.168.1.2,192.168.1.3"
./check-all-nodes.sh

# Check using hostnames via environment variable
export XRD_IPS="router1.example.com,router2.example.com,router3.example.com"
./check-all-nodes.sh

# Check custom IPs via command-line arguments
./check-all-nodes.sh cisco C1sco12345 192.168.1.1 192.168.1.2

# Check using hostnames via command-line arguments
./check-all-nodes.sh cisco C1sco12345 router1.example.com router2.example.com

# Combine: custom credentials and IPs via environment
export XRD_USERNAME=admin
export XRD_PASSWORD=secret
export XRD_IPS="10.10.10.29,10.10.10.30,10.10.10.31"
./check-all-nodes.sh

# Override everything via command line
./check-all-nodes.sh cisco C1sco12345 10.10.10.29 10.10.10.30 10.10.10.31
```

**Success output:**

```
✓ Overall Status: ALL SYSTEMS OPERATIONAL
Total Checks: 6
Passed: 6
Failed: 0
```

**Partial failure output:**

```
✗ Overall Status: SOME SYSTEMS DOWN
Total Checks: 6
Passed: 4
Failed: 2
```

**Notes:**

- The script will check all provided IPs/hostnames (default: 3 nodes = 6 checks)
- You can provide any number of IPs or hostnames via command-line or `$XRD_IPS`
- Hostnames are supported: NETCONF checks will auto-resolve to IP, gNMI uses hostnames directly
- Command-line IPs/hostnames take precedence over environment variables
- Ensure DNS is properly configured if using hostnames

---

## Installation

### Installing Prerequisites

#### Install uv (for NETCONF health check)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

#### Install gnmic (for gNMI health check)

```bash
# Using bash script (Linux/macOS)
bash -c "$(curl -sL https://get-gnmic.openconfig.net)"

# Or download binary from GitHub releases
# https://github.com/openconfig/gnmic/releases
```

---

## Integration with Always-On Deployment

These health check scripts can be used to verify the XRd router deployment in the always-on topology.

### Quick Start: Check All Nodes

```bash
# Navigate to the health-checks directory
cd /home/developer/XRd-Sandbox/scripts/deployment/always-on/health-checks

# Check all nodes (recommended)
./check-all-nodes.sh
```

### Individual Node Checks

```bash
# Check NETCONF connectivity for each node
./netconf-healthcheck.sh 10.10.20.101  # xrd-1
./netconf-healthcheck.sh 10.10.20.102  # xrd-2
./netconf-healthcheck.sh 10.10.20.103  # xrd-3

# Check gNMI connectivity for each node
./gnmi-healthcheck.sh 10.10.20.101 57777  # xrd-1
./gnmi-healthcheck.sh 10.10.20.102 57777  # xrd-2
./gnmi-healthcheck.sh 10.10.20.103 57777  # xrd-3
```

---

## Recommended Usage Frequency

The appropriate frequency for running health checks depends on your use case:

### 🎯 Development & Testing (Most Common)

**Recommendation: On-demand / As-needed**

```bash
# Run before starting work
./check-all-nodes.sh

# Run after making configuration changes
./check-all-nodes.sh

# Run if experiencing connectivity issues
./netconf-healthcheck.sh 10.10.20.101  # Test specific node/protocol
```

**Why:** The always-on sandbox is a shared learning environment. Running health checks only when needed:

- Reduces unnecessary load on shared resources
- Respects other users' testing activities
- Provides immediate feedback when you need it

### 🔧 Automation & CI/CD Integration

**Recommendation: Once per test run (start of pipeline)**

```bash
# In your CI/CD pipeline or automation script
if ! ./check-all-nodes.sh; then
    echo "Sandbox unavailable - skipping tests"
    exit 1
fi
# Proceed with your tests...
```

**Why:** Validates environment availability before automated testing.

### 📊 Monitoring (Use Sparingly)

**Recommendation: Maximum 1-2 times per hour**

```bash
# Example: Periodic monitoring (if absolutely needed)
*/30 * * * * /path/to/check-all-nodes.sh >> /var/log/xrd-health.log 2>&1
```

**⚠️ Important Notes:**

- The always-on sandbox is for **learning and development**, not production monitoring
- Aggressive monitoring (e.g., every few minutes) is **not appropriate** for this shared environment
- If you need continuous monitoring, consider requesting a dedicated sandbox reservation

### 🚫 Do NOT Use For

- ❌ Continuous monitoring at high frequency (< 30 minutes)
- ❌ Performance/load testing
- ❌ Production health monitoring
- ❌ Automated alerting systems

### 💡 Best Practice

**Use health checks as diagnostic tools, not continuous monitors.**

Run them:

- When you first connect to verify availability
- When troubleshooting connectivity issues
- After making significant configuration changes
- Before running important automation scripts

---

## Exit Codes

Both scripts follow standard exit code conventions:

- `0`: Success - service is healthy
- `1`: Failure - service is not reachable or not working

This makes them suitable for use in CI/CD pipelines and monitoring systems.

---

## Troubleshooting

### Hostname Resolution

**Both scripts support hostnames:**

- **NETCONF**: Hostnames are automatically resolved to IP addresses using Python's `socket` module (standard library)
- **gNMI**: Hostnames are passed directly to gnmic, which handles resolution natively

**Error: "Failed to resolve hostname"**

- Verify DNS is properly configured
- Check that the hostname is valid: `nslookup <hostname>` or `ping <hostname>`
- Use IP address directly as a workaround

### NETCONF Issues

**Error: "uv command not found"**

- Install uv using the instructions above

**Error: "Connection refused"**

- Verify the XRd container is running
- Check the port mapping in docker-compose.yml
- Verify the host IP address

**Error: "Authentication failed"**

- Verify username and password
- Check XRd configuration for user credentials

### gNMI Issues

**Error: "gnmic command not found"**

- Install gnmic using the instructions above

**Error: "connection timeout"**

- Verify the XRd container is running
- Check the gNMI port is exposed (default: 57777)
- Verify firewall rules allow connections

**Error: "rpc error"**

- Check gNMI is enabled in XRd configuration
- Verify TLS/SSL settings (scripts use --insecure for testing)

---

## Notes

- Both scripts use `--insecure` or `hostkey_verify=False` for simplicity in testing environments
- For production use, consider implementing proper certificate validation
- The scripts provide color-coded output for better visibility (green for success, red for failure)
- Output is intentionally simplified to show only essential information for health checking
