#!/bin/bash
set -e

### CONFIG ###
# These MUST be set before running - script will exit if still default values
TAILSCALE_AUTHKEY="tskey-xxxxxxxxxxxxxxxxxxxxxxxx"
CLIENT_NAME="CLIENT"
##############

echo "🔍 Tailscale Setup Starting..."

# Check if running with sufficient privileges
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: This script must be run as root or with sudo"
    echo "   Please run: sudo $0"
    exit 1
fi

if [ "$TAILSCALE_AUTHKEY" = "tskey-xxxxxxxxxxxxxxxxxxxxxxxx" ]; then
    echo "❌ ERROR: TAILSCALE_AUTHKEY is not configured!"
    echo "   Please set a real Tailscale auth key."
    echo "   Get one from: https://login.tailscale.com/admin/settings/keys"
    exit 1
fi

if [ "$CLIENT_NAME" = "CLIENT" ]; then
    echo "❌ ERROR: CLIENT_NAME is not configured!"
    echo "   Please edit this script."
    exit 1
fi

echo "🔌 Installing Tailscale..."
if ! curl -fsSL https://tailscale.com/install.sh | sh; then
    echo "❌ Failed to install Tailscale"
    exit 1
fi

echo "🌐 Connecting to Tailscale..."
if ! tailscale up --authkey "$TAILSCALE_AUTHKEY" --ssh --hostname "$CLIENT_NAME"; then
    echo "❌ Failed to connect to Tailscale"
    exit 1
fi

echo "🎉 Setup complete! The this device should now be visible in your Tailscale dashboard."
