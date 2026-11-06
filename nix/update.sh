#!/usr/bin/env bash
# Usage: nix/update.sh [version] (defaults to the latest stable release)
set -euo pipefail
cd "$(dirname "$0")"

version="${1:-$(curl -fsSL https://api.github.com/repos/roshancodespace/ShonenX/releases/latest | jq -er .tag_name | sed 's/^v//')}"
url="https://github.com/roshancodespace/ShonenX/releases/download/v${version}/ShonenX-Linux.zip"
hash="$(nix store prefetch-file --json "$url" | jq -er .hash)"

sed -i -E \
  -e "s|^([[:space:]]*version = )\"[^\"]+\";|\1\"${version}\";|" \
  -e "s|^([[:space:]]*hash = )\"[^\"]+\";|\1\"${hash}\";|" \
  package.nix

echo "Updated to ${version} (${hash})"
