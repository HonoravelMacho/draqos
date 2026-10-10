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
