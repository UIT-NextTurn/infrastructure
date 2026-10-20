#!/usr/bin/env bash
# ==============================================================================
# NextTurn Infrastructure - Common Network Initializer (Podman on Linux)
# Khởi tạo mạng cầu nối Podman dùng chung (Shared Network) cho các dịch vụ
# ==============================================================================

set -euo pipefail

NETWORK_NAME="nextturn-network"

echo "Checking for Podman network: '${NETWORK_NAME}'..."

if ! podman network exists "${NETWORK_NAME}" 2>/dev/null; then
    echo "Network '${NETWORK_NAME}' not found. Creating via Podman..."
    podman network create --driver bridge "${NETWORK_NAME}"
    echo "Podman shared network '${NETWORK_NAME}' created successfully!"
else
    echo "Podman shared network '${NETWORK_NAME}' is already present and ready."
fi
