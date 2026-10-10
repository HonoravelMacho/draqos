#!/usr/bin/env bash
# Build the portable Linux tarball (desktop app + daemon + systemd unit).
# Usage: build_tarball.sh <version>
set -euo pipefail
VER="${1:?version required}"
export STAGE="build/stage"
bash packaging/linux/stage.sh "$VER"
mkdir -p dist
tar -czf "dist/draqos-$VER-linux-x86_64.tar.gz" -C build/stage \
  usr/lib/draqos usr/bin/draqos usr/bin/draqosd \
  usr/share/applications/draqos.desktop lib/systemd/system/draqosd.service
echo "wrote dist/draqos-$VER-linux-x86_64.tar.gz"
