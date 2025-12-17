#!/usr/bin/env bash
#
# All Nodes Health Check Script
# This script performs health checks on all three XRd routers in the always-on topology
# Checks both NETCONF and gNMI connectivity for each node
#
# Usage: ./check-all-nodes.sh [username] [password]
# Example: ./check-all-nodes.sh cisco C1sco12345
#
# Environment Variables:
#   XRD_USERNAME - Username for authentication (default: cisco)
#   XRD_PASSWORD - Password for authentication (default: C1sco12345)

set -euo pipefail

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default credentials - environment variables take precedence over defaults
USERNAME="${1:-${XRD_USERNAME:-cisco}}"
PASSWORD="${2:-${XRD_PASSWORD:-C1sco12345}}"

# Function to get IP for a node (Bash 3.2 compatible)
get_node_ip() {
    case "$1" in
        xrd-1) echo "10.10.20.101" ;;
        xrd-2) echo "10.10.20.102" ;;
        xrd-3) echo "10.10.20.103" ;;
        *) echo "" ;;
    esac
}

# Ports
NETCONF_PORT=830
GNMI_PORT=57777

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Counters
total_checks=0
passed_checks=0
failed_checks=0

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   XRd Always-On Topology - Health Check Report${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo ""
echo "Checking 3 nodes × 2 protocols = 6 total checks"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Function to run a health check
run_check() {
    local node_name=$1
    local protocol=$2
    local ip=$3
    
    total_checks=$((total_checks + 1))
    
    echo -e "${BLUE}[$node_name - $protocol]${NC} Testing ${ip}..."
    
    if [ "$protocol" = "NETCONF" ]; then
        if "$SCRIPT_DIR/netconf-healthcheck.sh" "$ip" "$NETCONF_PORT" "$USERNAME" "$PASSWORD" > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ $node_name $protocol: PASS${NC}"
            passed_checks=$((passed_checks + 1))
            return 0
        else
            echo -e "${RED}  ✗ $node_name $protocol: FAIL${NC}"
            failed_checks=$((failed_checks + 1))
            return 1
        fi
    elif [ "$protocol" = "gNMI" ]; then
        if "$SCRIPT_DIR/gnmi-healthcheck.sh" "$ip" "$GNMI_PORT" "$USERNAME" "$PASSWORD" > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ $node_name $protocol: PASS${NC}"
            passed_checks=$((passed_checks + 1))
            return 0
        else
            echo -e "${RED}  ✗ $node_name $protocol: FAIL${NC}"
            failed_checks=$((failed_checks + 1))
            return 1
        fi
    fi
}

# Check all nodes
for node in xrd-1 xrd-2 xrd-3; do
    ip="$(get_node_ip "$node")"
    echo ""
    echo -e "${YELLOW}━━━ Checking $node ($ip) ━━━${NC}"
    
    # Check NETCONF
    run_check "$node" "NETCONF" "$ip"
    
    # Check gNMI
    run_check "$node" "gNMI" "$ip"
done

# Summary
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                    Summary${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo ""
echo "Total Checks:  $total_checks"
echo -e "${GREEN}Passed:        $passed_checks${NC}"
echo -e "${RED}Failed:        $failed_checks${NC}"
echo ""

# Overall status
if [ $failed_checks -eq 0 ]; then
    echo -e "${GREEN}✓ Overall Status: ALL SYSTEMS OPERATIONAL${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Overall Status: SOME SYSTEMS DOWN${NC}"
    echo ""
    echo "Tip: Run individual health checks for detailed error messages:"
    echo "  ./netconf-healthcheck.sh <ip> $NETCONF_PORT $USERNAME $PASSWORD"
    echo "  ./gnmi-healthcheck.sh <ip> $GNMI_PORT $USERNAME $PASSWORD"
    echo ""
    exit 1
fi
