#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

GCS_BASE="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
VERSION_FILE="version.json"

echo -e "${YELLOW}Fetching latest version...${NC}"
NEW_VERSION=$(curl -fsSL "$GCS_BASE/latest")
echo -e "${GREEN}Latest version: $NEW_VERSION${NC}"

# Get current version from version.json
CURRENT_VERSION=$(jq -r '.version' "$VERSION_FILE")
echo -e "Current version: $CURRENT_VERSION"

if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
    echo -e "${GREEN}Already at latest version!${NC}"
    exit 0
fi

echo -e "${YELLOW}Fetching manifest for version $NEW_VERSION...${NC}"
MANIFEST=$(curl -fsSL "$GCS_BASE/$NEW_VERSION/manifest.json")

# Function to convert hex checksum to nix base64 format
hex_to_nix_hash() {
    local hex_hash=$1
    # Convert from hex to SRI format (defaults to sri when --to is omitted)
    nix hash convert --hash-algo sha256 "$hex_hash"
}

echo -e "${YELLOW}Converting checksums...${NC}"

# Extract and convert checksums for each platform
LINUX_X64_HEX=$(echo "$MANIFEST" | jq -r '.platforms["linux-x64"].checksum')
LINUX_ARM64_HEX=$(echo "$MANIFEST" | jq -r '.platforms["linux-arm64"].checksum')
DARWIN_X64_HEX=$(echo "$MANIFEST" | jq -r '.platforms["darwin-x64"].checksum')
DARWIN_ARM64_HEX=$(echo "$MANIFEST" | jq -r '.platforms["darwin-arm64"].checksum')

LINUX_X64_HASH=$(hex_to_nix_hash "$LINUX_X64_HEX")
LINUX_ARM64_HASH=$(hex_to_nix_hash "$LINUX_ARM64_HEX")
DARWIN_X64_HASH=$(hex_to_nix_hash "$DARWIN_X64_HEX")
DARWIN_ARM64_HASH=$(hex_to_nix_hash "$DARWIN_ARM64_HEX")

echo -e "${YELLOW}Updating $VERSION_FILE...${NC}"

# Update version.json using jq
jq --arg version "$NEW_VERSION" \
   --arg linux_x64 "$LINUX_X64_HASH" \
   --arg linux_arm64 "$LINUX_ARM64_HASH" \
   --arg darwin_x64 "$DARWIN_X64_HASH" \
   --arg darwin_arm64 "$DARWIN_ARM64_HASH" \
   '.version = $version | .hashes["linux-x64"] = $linux_x64 | .hashes["linux-arm64"] = $linux_arm64 | .hashes["darwin-x64"] = $darwin_x64 | .hashes["darwin-arm64"] = $darwin_arm64' \
   "$VERSION_FILE" > "$VERSION_FILE.tmp"

# Replace original file
mv "$VERSION_FILE.tmp" "$VERSION_FILE"

echo -e "${GREEN}✓ Updated to version $NEW_VERSION${NC}"
echo -e "${YELLOW}Changes:${NC}"
echo "  Version: $CURRENT_VERSION → $NEW_VERSION"
echo "  linux-x64: $LINUX_X64_HASH"
echo "  linux-arm64: $LINUX_ARM64_HASH"
echo "  darwin-x64: $DARWIN_X64_HASH"
echo "  darwin-arm64: $DARWIN_ARM64_HASH"
echo ""
echo -e "${YELLOW}Run 'nix flake check' to verify the update${NC}"
