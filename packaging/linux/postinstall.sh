#!/bin/sh
# postinstall: dedicated user, data dir, enable service.
set -e
if ! id draqos >/dev/null 2>&1; then
  useradd --system --home-dir /var/lib/draqosd --create-home \
    --shell /usr/sbin/nologin draqos
fi
mkdir -p /var/lib/draqosd
chown draqos:draqos /var/lib/draqosd
chmod 700 /var/lib/draqosd
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload || true
  systemctl enable draqosd.service || true
  echo "draqosd installed. Start it with: sudo systemctl start draqosd"
fi
