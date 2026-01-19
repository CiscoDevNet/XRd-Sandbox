#!/usr/bin/env bash
#
# All Nodes Health Check Script
# This script performs health checks on XRd routers
# Checks both NETCONF and gNMI connectivity for each node
#
# Usage: ./check-all-nodes.sh [username] [password] [ip1] [ip2] [ip3] ...
# Example: ./check-all-nodes.sh cisco C1sco12345 10.10.20.101 10.10.20.102
#
# Environment Variables:
#   XRD_USERNAME - Username for authentication (default: cisco)
#   XRD_PASSWORD - Password for authentication (default: C1sco12345)
#   XRD_IPS      - Comma-separated list of IPs (default: 10.10.20.101,10.10.20.102,10.10.20.103)
#
# Examples:
#   ./check-all-nodes.sh                                          # Use all defaults
#   XRD_IPS="192.168.1.1,192.168.1.2" ./check-all-nodes.sh       # Custom IPs via env var
#   ./check-all-nodes.sh cisco C1sco12345 192.168.1.1 192.168.1.2 # Custom IPs via args

set -uo pipefail

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

# Default IPs for always-on topology
DEFAULT_IPS="10.10.20.101,10.10.20.102,10.10.20.103"

# Get IPs from command-line args (if provided), otherwise from env var, otherwise use defaults
if [ $# -gt 2 ]; then
    # IPs provided as command-line arguments (all args after username and password)
    shift 2  # Remove username and password from args
    IPS_ARRAY=("$@")
else
    # Use environment variable or defaults
    IPS_STRING="${XRD_IPS:-$DEFAULT_IPS}"
    # Convert comma-separated string to array
    IFS=',' read -ra IPS_ARRAY <<< "$IPS_STRING"
fi

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
echo -e "${CYAN}        XRd Health Check Report${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo ""
echo "Target IPs: ${IPS_ARRAY[*]}"
echo ""

# Dependency Check
echo "Checking dependencies..."
dependency_issues=0

if command -v uv &> /dev/null; then
    echo -e "${GREEN}✓${NC} uv: Available (for NETCONF checks)"
else
    echo -e "${RED}✗${NC} uv: Not found - NETCONF checks will fail"
    dependency_issues=1
fi

if command -v gnmic &> /dev/null; then
    echo -e "${GREEN}✓${NC} gnmic: Available (for gNMI checks)"
else
    echo -e "${RED}✗${NC} gnmic: Not found - gNMI checks will fail"
    dependency_issues=1
fi

if [ $dependency_issues -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}⚠ WARNING${NC}: Some dependencies are missing. Relevant checks will fail."
    echo "  Install uv: https://docs.astral.sh/uv/getting-started/installation/"
    echo "  Install gnmic: https://gnmic.openconfig.net/install/"
fi

echo ""
echo "Checking ${#IPS_ARRAY[@]} nodes × 2 protocols = $((${#IPS_ARRAY[@]} * 2)) total checks"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Array to store results (Bash 3.2 compatible using string concatenation)
results=""

# Function to run a health check
run_check() {
    local node_name=$1
    local protocol=$2
    local ip=$3
    
    total_checks=$((total_checks + 1))
    
    echo -e "${BLUE}[$node_name - $protocol]${NC} Testing ${ip}..."
    
    local check_passed=0
    
    if [ "$protocol" = "NETCONF" ]; then
        if "$SCRIPT_DIR/netconf-healthcheck.sh" "$ip" "$NETCONF_PORT" "$USERNAME" "$PASSWORD" > /dev/null 2>&1; then
            check_passed=1
        fi
    elif [ "$protocol" = "gNMI" ]; then
        if "$SCRIPT_DIR/gnmi-healthcheck.sh" "$ip" "$GNMI_PORT" "$USERNAME" "$PASSWORD" > /dev/null 2>&1; then
            check_passed=1
        fi
    fi
    
    if [ $check_passed -eq 1 ]; then
        echo -e "${GREEN}  ✓ $node_name $protocol: PASS${NC}"
        passed_checks=$((passed_checks + 1))
        results="${results}PASS|$node_name|$protocol|$ip\n"
    else
        echo -e "${RED}  ✗ $node_name $protocol: FAIL${NC}"
        failed_checks=$((failed_checks + 1))
        results="${results}FAIL|$node_name|$protocol|$ip\n"
    fi
}

# Check all nodes
node_index=1
for ip in "${IPS_ARRAY[@]}"; do
    # Trim whitespace from IP
    ip=$(echo "$ip" | xargs)
    
    node_name="node-$node_index"
    echo ""
    echo -e "${YELLOW}━━━ Checking $node_name ($ip) ━━━${NC}"
    
    # Check NETCONF
    run_check "$node_name" "NETCONF" "$ip"
    
    # Check gNMI
    run_check "$node_name" "gNMI" "$ip"
    
    node_index=$((node_index + 1))
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

# Display detailed results table
if [ $failed_checks -gt 0 ]; then
    echo -e "${YELLOW}Failed Checks Details:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "$(echo -e "$results" | grep '^FAIL' | while IFS='|' read -r status node protocol ip; do
        echo -e "  ${RED}✗${NC} $node - $protocol ($ip)"
    done)"
    echo ""
fi

if [ $passed_checks -gt 0 ]; then
    echo -e "${GREEN}Passed Checks Details:${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "$(echo -e "$results" | grep '^PASS' | while IFS='|' read -r status node protocol ip; do
        echo -e "  ${GREEN}✓${NC} $node - $protocol ($ip)"
    done)"
    echo ""
fi

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
