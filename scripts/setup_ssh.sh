#!/bin/bash
set -e

# Source environment variables
source sandbox_env_vars.sh

# Define ControlPath for SSH connection sharing
# Using %r@%h:%p ensures a unique path per user/host/port
CONTROL_PATH="/tmp/ssh_mux_%r@%h:%p"

# Ensure the directory for the control socket exists
mkdir -p "$(dirname "$CONTROL_PATH")"

echo "=== Setting up SSH key for the sandbox VM ==="
echo "Using SSH key path: $SSH_KEY_PATH"

# Ensure remote .ssh directory and authorized_keys file exist, remove old sandbox key, using ControlMaster
echo "Establishing control connection and removing any existing sandbox key from remote host..."
ssh -o ControlMaster=auto -o ControlPersist=10s -o ControlPath="$CONTROL_PATH" \
    "$SANDBOX_USER@$SANDBOX_IP" \
    "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && sed -i '/sandbox@built.com/d' ~/.ssh/authorized_keys"

# Trap to ensure control master is closed on exit
trap 'ssh -O exit -o ControlPath="$CONTROL_PATH" "$SANDBOX_USER@$SANDBOX_IP" 2>/dev/null || true' EXIT

echo "Generating new SSH key pair, overwriting if exists..."
# Ensure local directory exists
mkdir -p "$(dirname "$SSH_KEY_PATH")"
# Generate new key, overwrite without prompt
yes y | ssh-keygen -t rsa -b 4096 -C "sandbox@built.com" -f "$SSH_KEY_PATH" -N ""

echo "Copying new public key to remote host (reusing control connection)..."
# Copy the new key, reusing the ControlMaster connection
ssh-copy-id -o ControlPath="$CONTROL_PATH" -f -i "$SSH_KEY_PATH.pub" "$SANDBOX_USER@$SANDBOX_IP"

# Explicitly close the control master connection (optional due to ControlPersist and trap)
# ssh -O exit -o ControlPath="$CONTROL_PATH" "$SANDBOX_USER@$SANDBOX_IP" 2>/dev/null || true

echo -e "\033[32m=== SSH setup completed successfully! ===\033[0m" 