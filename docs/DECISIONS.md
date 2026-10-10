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
