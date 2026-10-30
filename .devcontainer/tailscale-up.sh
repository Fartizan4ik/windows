#!/bin/sh
set -e
STATE=/workspaces/windows/.devcontainer/tailscale
mkdir -p "$STATE"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1
fi
if ! pgrep -x tailscaled >/dev/null 2>&1; then
  mkdir -p /var/run/tailscale
  nohup tailscaled --state="$STATE/tailscaled.state" --socket=/var/run/tailscale/tailscaled.sock >/var/log/tailscaled.log 2>&1 &
  sleep 4
fi
tailscale up --hostname=dockur-win --accept-dns=false --accept-routes=false || true
tailscale ip -4 || true