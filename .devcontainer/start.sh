#!/usr/bin/env bash
set -e

# 1. Install standalone node.js in background for Codespaces agent/ssh
if ! command -v node >/dev/null 2>&1; then
  (
    mkdir -p /tmp/node
    if curl -fsSL https://nodejs.org/dist/v20.18.0/node-v20.18.0-linux-x64.tar.gz 2>/dev/null | tar -xz -C /tmp/node --strip-components=1 2>/dev/null; then
      cp /tmp/node/bin/node /usr/local/bin/node 2>/dev/null || true
      chmod +x /usr/local/bin/node 2>/dev/null || true
    fi
    rm -rf /tmp/node
  ) >/dev/null 2>&1 &
fi

# 2. Launch Tailscale in background
(
  for i in $(seq 1 30); do
    if [ -f "/workspaces/windows/.devcontainer/tailscale-up.sh" ]; then
      sh /workspaces/windows/.devcontainer/tailscale-up.sh >/tmp/tailscale.log 2>&1
      break
    fi
    sleep 2
  done
) >/dev/null 2>&1 &

# 3. Prune leftover ISO installers if Windows is already installed (frees ~4.5 GB)
if [ -f "/storage/windows.boot" ] || [ -f "/storage/windows.img" ]; then
  rm -f /storage/custom.iso /storage/boot.iso /tmp/*.iso 2>/dev/null || true
fi

# 4. Enforce 10G RAM size
export RAM_SIZE="10G"

return 0 2>/dev/null || exit 0
