#!/usr/bin/env bash
#
# NETCONF Health Check Script
# This script performs a simple NETCONF connectivity test by sending a hello message
# to verify that the NETCONF interface is operational.
#
# Usage: ./netconf-healthcheck.sh [host] [port] [username] [password]
# Example: ./netconf-healthcheck.sh 10.10.20.101 830 cisco C1sco12345
#
# Environment Variables:
#   XRD_USERNAME - Username for authentication (default: cisco)
#   XRD_PASSWORD - Password for authentication (default: C1sco12345)

set -uo pipefail

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values - environment variables take precedence over defaults
HOST="${1:-10.10.20.101}"
PORT="${2:-830}"
USERNAME="${3:-${XRD_USERNAME:-cisco}}"
PASSWORD="${4:-${XRD_PASSWORD:-C1sco12345}}"

echo "======================================"
echo "  NETCONF Health Check"
echo "======================================"
echo "Host: $HOST"
echo "Port: $PORT"
echo "User: $USERNAME"
echo "======================================" 
echo ""

# Dependency Check
echo "Checking dependencies..."
dependency_missing=0

if command -v uv &> /dev/null; then
    echo -e "${GREEN}✓${NC} uv: Available ($(which uv))"
else
    echo -e "${RED}✗${NC} uv: Not found - required for running Python with ncclient"
    dependency_missing=1
fi

if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✓${NC} python3: Available (version $(python3 --version 2>&1 | cut -d' ' -f2))"
else
    echo -e "${YELLOW}⚠${NC} python3: Not found (not required if uv is available)"
fi

echo ""

if [ $dependency_missing -eq 1 ]; then
    echo -e "${RED}✗ FAILED${NC}: Missing required dependencies. Cannot proceed with health check."
    echo "Please install uv: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi

# Perform NETCONF health check using ncclient
echo "Connecting to NETCONF server (30s timeout)..."

if uv run --with ncclient python -c "
from ncclient import manager
import sys

try:
    with manager.connect(
        host='$HOST',
        port=$PORT,
        username='$USERNAME',
        password='$PASSWORD',
        hostkey_verify=False,
        device_params={'name': 'iosxr'},
        timeout=30
    ) as session:
        # Just getting the hello message is enough for health check
        print('Session ID:', session.session_id)
        print('Server capabilities count:', len(session.server_capabilities))
        sys.exit(0)
except Exception as e:
    print(f'Connection failed: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1; then
    echo ""
    echo -e "${GREEN}✓ SUCCESS${NC}: NETCONF is working!"
    exit 0
else
    echo ""
    echo -e "${RED}✗ FAILED${NC}: NETCONF connection failed!"
    exit 1
fi
