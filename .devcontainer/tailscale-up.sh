#!/bin/sh
set -e

STATE="/workspaces/windows/.devcontainer/tailscale"
mkdir -p "$STATE"
mkdir -p /var/run/tailscale

# 1. Install Tailscale if missing
if ! command -v tailscale >/dev/null 2>&1; then
  echo "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1 || true
fi

# 2. Ensure /dev/net/tun exists
if [ ! -c /dev/net/tun ]; then
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200 2>/dev/null || true
fi

# 3. Start tailscaled daemon
if ! pgrep -x tailscaled >/dev/null 2>&1; then
  echo "Starting tailscaled daemon..."
  nohup tailscaled --state="$STATE/tailscaled.state" --socket=/var/run/tailscale/tailscaled.sock >/var/log/tailscaled.log 2>&1 &
  sleep 4
fi

# 4. Bring up Tailscale
echo "Bringing up Tailscale..."
if [ -n "$TS_AUTH_KEY" ]; then
  tailscale up --authkey="$TS_AUTH_KEY" --hostname=dockur-win --accept-dns=false --accept-routes=false || true
else
  tailscale up --hostname=dockur-win --accept-dns=false --accept-routes=false --timeout=15s 2>&1 | tee /tmp/tailscale-up-last.txt || true
fi

IP=$(tailscale ip -4 2>/dev/null || true)
if [ -n "$IP" ]; then
  echo "Tailscale active on IP: $IP"
else
  echo "Tailscale login needed:"
  grep -o 'https://login.tailscale.com/a/[a-zA-Z0-9]*' /tmp/tailscale-up-last.txt 2>/dev/null || true
fi
