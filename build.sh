#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== GivSelf Docker Build ==="
echo ""

# Step 1: Build contracts tarball
echo "1/3 Building contracts..."
cd "$ROOT/givself-contracts"
npm run build
npm run pack
TARBALL="$ROOT/givself-contracts/givself-contracts-0.2.0.tgz"

if [ ! -f "$TARBALL" ]; then
    echo "ERROR: Contracts tarball not found at $TARBALL"
    exit 1
fi
echo "    Tarball: $TARBALL"

# Step 2: Copy tarball to service directories
echo ""
echo "2/3 Distributing contracts..."
cp "$TARBALL" "$ROOT/givself-server/"
cp "$TARBALL" "$ROOT/givself-web/"
echo "    Copied to givself-server/ and givself-web/"

# Step 3: Docker compose build
echo ""
echo "3/3 Building Docker images..."
cd "$SCRIPT_DIR"
docker compose build "$@"

echo ""
echo "=== Build complete ==="
echo ""
echo "To start:  cd $(basename "$SCRIPT_DIR") && docker compose up -d"
echo "To stop:   docker compose down"
echo "Logs:      docker compose logs -f"
