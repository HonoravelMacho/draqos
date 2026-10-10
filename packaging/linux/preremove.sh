#!/bin/sh
# preremove: stop/disable the service (data dir is kept).
set -e
if command -v systemctl >/dev/null 2>&1; then
  systemctl stop draqosd.service || true
  systemctl disable draqosd.service || true
fi
