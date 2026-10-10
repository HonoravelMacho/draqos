# DRAQOS — Dynamic Render of Artistic QR (open source)

Design QR codes with your own shapes, colors and images — and keep **dynamic**
ones whose destination you can edit later, served privately from your own
computer over Tailscale. MIT licensed, still learning, still improving.

> 🇧🇷 Fala português? Leia o [README.pt-BR.md](README.pt-BR.md).

## What it is

- **Static studio**: full-blown artistic QR editor — stroke/background colors
  (custom color picker), background images, frame presets (square, heart,
  A4-landscape 1:1.414, golden 1:1.618, free ratio), dot styles (square,
  rounded, heart), independently styled finder eyes, auto-contrast against
  the background image, center icon (PNG/SVG, optional "invade transparent
  areas" aesthetic), error correction level H, respected quiet zone,
  one-tap **Test read** (zxing2 decode) and **PNG / SVG / PDF** export.
- **Dynamic QRs**: the printed code holds a stable URL
  `https://<machine>.<tailnet>.ts.net/r/<id>`; you edit the destination
  anytime without reprinting. Served by `draqosd`, a headless Dart daemon
  on your own PC, with scan counting (timestamps only — **no IPs, no
  personal data**).
- **Sci-Fi Game GUI**: no native-looking buttons anywhere; metallic beveled
  panels, neon glow, corner brackets and scanlines, all driven by design
  tokens (`DraqosTokens`) in one place.

## Install (simple path per platform)

Download the [latest release](../../releases) (`v*` tags):

| Platform | File | Notes |
|---|---|---|
| Android | `draqos-*-android.apk` (or `-android-debug.apk`) | See *APK signature* below |
| Windows | `draqos-*-windows-setup.exe` | Includes the app + `draqosd`; optional start-at-logon task |
| Linux (Debian/Ubuntu/Pop!) | `draqos_*_amd64.deb` | Daemon + app + systemd unit |
| Linux (Fedora/openSUSE) | `draqos-*.x86_64.rpm` | Same payload as the `.deb` |
| Linux (any distro) | `draqos-*-linux-x86_64.tar.gz` | Portable: app bundle + daemon + unit file |

After installing the Linux package:

```bash
sudo systemctl start draqosd
systemctl status draqosd
```

### APK signature

Releases built **without** signing secrets ship a **debug-signed APK**
(`-android-debug.apk`): fine for sideloading/testing, **not** for the Play
Store. To ship a store-signed build, maintainers add these repo secrets and
re-tag: `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. The release workflow then
publishes a properly signed `draqos-*-android.apk`.

## Pair Android ↔ PC

1. On the PC: install Tailscale, log in, and make sure `tailscaled` runs.
2. Start `draqosd` (systemd on Linux, logon task on Windows, or run it —
   the desktop app's **Daemon** tab can start/stop a local one).
3. Desktop app → **Pair** tab → **Show pairing QR**. It shows a QR encoding
   the tailnet base URL + admin token.
4. Android app → **Pair** tab → paste the `draqos://pair?...` code
   (camera scanning is a planned enhancement; paste works everywhere).
5. The **Dynamic** tab now lists/creates/edits your dynamic QRs.

## Enable public dynamic QRs (Tailscale Funnel)

Only the redirect path `/r/<id>` is ever made public; the admin API stays
on the tailnet.

```bash
# tailnet-only admin + editor channel
tailscale serve --bg --https=443 http://127.0.0.1:8471

# public channel: ONLY /r/* (Funnel ports: 443, 8443 or 10000;
# a port cannot be Serve- and Funnel-shared at the same time)
tailscale funnel --bg --https=443 --set-path=/r http://127.0.0.1:8471/r
```

Printed dynamic QRs look like `https://mypc.cool-tail.ts.net/r/abc123`.

## Honest limitations

- **PC off = dynamic QRs down.** Codes resolve through your machine; if it
  sleeps, powers off, or Tailscale drops, scans fail. Static QRs always work.
- **Renaming the machine/tailnet breaks printed dynamic QRs** (the URL embeds
  the DNS name). The app warns before such actions; reprint after renaming.
- **Android allows one VPN at a time**: Tailscale must be the active one for
  the editor to reach the PC.
- **Funnel needs HTTPS + the funnel node attribute** in your tailnet policy
  (the CLI guides you on first `funnel` run) and takes ~10 min for public DNS.
- Camera pairing scan is not in v0.1.0 (paste the code instead).
- PDF export approximates rounded/heart dots as circles; SVG is exact.

## Build from source

```bash
flutter pub get            # pub workspace at the repo root
dart tool/check_architecture.dart
dart test packages/draqos_core packages/draqos_client packages/draqos_server
flutter test packages/draqos_ui packages/draqos_render apps/draqos_app
dart compile exe packages/draqos_server/bin/draqosd.dart -o build/draqosd
```

API contract: [`docs/api.yaml`](docs/api.yaml). Architecture:
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Decisions:
[`docs/DECISIONS.md`](docs/DECISIONS.md). Contributing:
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Privacy

Scan counters store **timestamps only**. No IPs, no user agents, no personal
data — asserted by an automated test (`PRAGMA table_info(scans)`).
