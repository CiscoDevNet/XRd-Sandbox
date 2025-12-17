#!/usr/bin/env bash
#
# gNMI Health Check Script
# This script performs a simple gNMI connectivity test by checking capabilities
# to verify that the gNMI interface is operational.
#
# Usage: ./gnmi-healthcheck.sh [host] [port] [username] [password]
# Example: ./gnmi-healthcheck.sh 10.10.20.101 57777 cisco C1sco12345
#
# Environment Variables:
#   XRD_USERNAME - Username for authentication (default: cisco)
#   XRD_PASSWORD - Password for authentication (default: C1sco12345)

set -euo pipefail

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values - environment variables take precedence over defaults
HOST="${1:-10.10.20.101}"
PORT="${2:-57777}"
USERNAME="${3:-${XRD_USERNAME:-cisco}}"
PASSWORD="${4:-${XRD_PASSWORD:-C1sco12345}}"

echo "======================================"
echo "  gNMI Health Check"
echo "======================================"
echo "Target: $HOST:$PORT"
echo "User: $USERNAME"
echo "======================================" 
echo ""

# Check if gnmic is available
if ! command -v gnmic &> /dev/null; then
    echo -e "${RED}✗ FAILED${NC}: 'gnmic' command not found. Please install gnmic first."
    exit 1
fi

# Perform gNMI health check
echo "Connecting to gNMI server..."

# Run gnmic and capture output
output=$(gnmic \
  --address "$HOST:$PORT" \
  --username "$USERNAME" \
  --password "$PASSWORD" \
  --insecure \
  --encoding JSON_IETF \
  capabilities 2>&1)

exit_code=$?

if [ $exit_code -eq 0 ]; then
    # Parse and display simplified output
    echo ""
    echo "gNMI Server Information:"
    echo "$output" | grep -E "gNMI version|version:" | head -2
    
    # Count supported encodings
    encoding_count=$(echo "$output" | grep -c "supported models:" || echo "0")
    echo ""
    echo "Status: Connected successfully"
    
    echo ""
    echo -e "${GREEN}✓ SUCCESS${NC}: gNMI is working!"
    exit 0
else
    echo ""
    echo "Error output:"
    echo "$output" | grep -i error || echo "$output" | head -5
    echo ""
    echo -e "${RED}✗ FAILED${NC}: gNMI connection failed!"
    exit 1
fi
