#!/usr/bin/env bash
# Assemble the Linux staging tree consumed by nfpm (.deb/.rpm) and tarball.
# Usage: stage.sh <version>  (env: STAGE defaults to build/stage)
set -euo pipefail
VER="${1:?version required}"
STAGE="${STAGE:-build/stage}"
APP_BUNDLE="apps/draqos_app/build/linux/x64/release/bundle"

rm -rf "$STAGE"
mkdir -p "$STAGE/usr/lib/draqos" "$STAGE/usr/bin" \
         "$STAGE/usr/share/applications" "$STAGE/usr/share/doc/draqos" \
         "$STAGE/lib/systemd/system"

cp build/draqosd "$STAGE/usr/lib/draqos/draqosd"
chmod 755 "$STAGE/usr/lib/draqos/draqosd"

if [ -d "$APP_BUNDLE" ]; then
  cp -r "$APP_BUNDLE/." "$STAGE/usr/lib/draqos/app/"
  ln -sf /usr/lib/draqos/app/draqos_app "$STAGE/usr/bin/draqos"
fi
ln -sf /usr/lib/draqos/draqosd "$STAGE/usr/bin/draqosd"

cp packaging/linux/draqosd.service "$STAGE/lib/systemd/system/draqosd.service"
cp packaging/linux/draqos.desktop "$STAGE/usr/share/applications/draqos.desktop"
cp LICENSE "$STAGE/usr/share/doc/draqos/copyright"
echo "$VER" > "$STAGE/usr/lib/draqos/VERSION"
echo "staged $VER in $STAGE"
