#!/bin/sh
set -e

# Workaround for WebKitGTK DMA-BUF issue with NVIDIA and Wayland
export WEBKIT_DISABLE_DMABUF_RENDERER="${WEBKIT_DISABLE_DMABUF_RENDERER:-1}"

# Prioritize bundled libraries
export LD_LIBRARY_PATH="/app/lib/shonenx/lib:/app/lib:${LD_LIBRARY_PATH}"

exec /app/lib/shonenx/shonenx "$@"
