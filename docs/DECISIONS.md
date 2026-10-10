# DRAQOS Decisions Log

Autonomous build decisions (no blocking questions asked).

## M1 — Monorepo, core, theme, architecture test
- **Pub workspaces** (Dart >=3.8) for the monorepo: single resolution,
  `packages/*` + `apps/*`. Chosen over melos to keep zero extra tooling.
- **State: Riverpod** (`flutter_riverpod`) in the app composition layer
  only; packages stay framework-agnostic where required.
- **QR matrix lib: `qr` (pure Dart)** for encoding; `image` for raster
  ops, `pdf` for PDF export, `zxing2` for decode-verification tests.
- **Server: `shelf` + `shelf_router` + `sqlite3`** (single-file DB,
  no personal data — timestamps only).
- **Tailscale syntax verified against official docs (2026)**:
  `tailscale serve --bg <port>`, `tailscale funnel --bg <port>`,
  status via `tailscale status --json`. Funnel limited to ports
  443/8443/10000 and cannot share a port with Serve — the
  `TailscaleFunnelProvider` enforces this.
- **Icons**: user-supplied `assets/branding/draqos_logo.*` (pixel dragon)
  is the canonical branding; launcher icons generated from it via
  `flutter_launcher_icons`.
- **Token hygiene**: `GITHUB_TOKEN` read only from the environment;
  remote URLs never embed the token (`gh auth` / credential helper).

## M2 — Render, static editor, export, readability tests
- **Frame = decoration, matrix = sacred**: the QR square (with quiet
  zone) is always painted intact and centered; presets only change the
  outer board. Full-bleed background fill guarantees decodability even
  where shaped boards (heart notch) leave gaps.
- **Heart modules need separation** (`deflate 0.12u`): touching hearts
  mis-sample as blobs (ChecksumException in zxing2 at some aspects).
- **Icon modes**: default knocks out modules under a backdrop (safe);
  `iconInvadeTransparent` lets modules show through transparency
  (prettier, riskier — user must press "Test read").
- **flutter_test + `Picture.toImage`**: must run inside
  `tester.runAsync` (fake-async zone), else the test hangs forever.
- **SVG heart modules** use `<path>`; **PDF** approximates rounded/heart
  as circles (documented in code). Auto-contrast is raster-only for now.
- **App branding copy**: canonical logos live in `/assets/branding`;
  `apps/draqos_app/assets/branding` is a build-required copy.

## M3 — Daemon, API, CRUD, counter, tunnel providers
- **Tailscale syntax confirmed live** in official docs (serve ref
  validated 2026-01-26, funnel overview 2026-01-20):
  `serve --bg --https=443 [--set-path=...] <target>`,
  `funnel <target>`; funnel ports 443/8443/10000 only; one port cannot
  be serve+funnel at once (last command wins); `--bg` survives reboot.
  Only `http://127.0.0.1` targets are supported for proxies.
- **Admin never public**: funnel is scoped with `--set-path=/r` to the
  redirect subtree; if scoping fails the provider returns Err and
  refuses to go public (fail-closed).
- **Daemon binds localhost only** (default 8471); Serve/Funnel do the
  exposing. Public QR URL = `https://<machine>.<tailnet>.ts.net/r/<id>`.
- **Privacy**: scans table = (qr_id, scanned_at) only; asserted in tests
  via PRAGMA table_info.
- **Auth**: 32-byte hex bearer, owner-only file, constant-time compare,
  explicit rotation endpoint.
- **Smoke-tested for real**: booted `draqosd`, 401 unauthenticated, 201
  create, 302 redirect, stats counted, 404 unknown id. Tailscale
  funnel/serve commands were NOT executed live (no tailnet here) — the
  CLI arg shapes are unit-tested with a fake runner.

## M4 — Client, dynamic screens, pairing, composition
- **Pairing = paste, not camera (v0.1.0)**: desktop renders the
  `draqos://pair?...` code as a QR; editors paste it. Camera scanning
  (mobile_scanner) deferred — keeps Android/desktop builds dependency-
  light; documented as pending in README.
- **Android is client-only**: daemon controls hidden behind
  `isAndroidProvider`; unreachable errors map to actionable hints
  (PC asleep/offline, Tailscale off, single-VPN-on-Android).
- **FutureBuilder footgun found by tests**: recreating the future in
  `build` + spinner animation = eternal waiting. Dynamic list caches
  the future in State and reloads only on tick/repo change.
- **Hostname/tailnet warnings**: pairing + daemon screens warn that
  renames break printed QRs; delete dialog warns about 404s.

## M5 — Packaging, CI, release
- **Platform shells** via `flutter create` (android/linux/windows only —
  the required targets), then `flutter_launcher_icons` from the user's
  dragon logo (`dev.draqos.draqos_app` namespace kept).
- **One nfpm source of truth** for .deb/.rpm (same staging tree as the
  tarball via `stage.sh`); systemd unit runs a dedicated `draqos` user
  with `/var/lib/draqosd`. Windows ships an Inno Setup installer with an
  optional logon task for the daemon.
- **APK without secrets = debug-signed** (`-android-debug.apk`), exactly
  as specced; store signing only when the four `ANDROID_*` secrets exist.
- **Tag `v*` triggers the release workflow** (linux deb/rpm/tar.gz +
  android apk + windows installer + SHA256SUMS via softprops release).
  Locally validated: daemon `compile exe`, Linux GUI build, tarball
  contents + GUI binary link/run-smoke, nfpm deb+rpm assembly.
  Not validated locally: Windows installer, store-signed APK, actual
  Play Store / distro repos submission.
