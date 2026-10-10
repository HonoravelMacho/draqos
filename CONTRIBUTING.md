# Contributing to DRAQOS

Thanks for helping! DRAQOS is MIT-licensed and beginner-friendly.

## Setup

1. Install Flutter (stable) and Dart.
2. `flutter pub get` at the repo root (pub workspace).
3. Run checks: `dart tool/check_architecture.dart`,
   `dart test` inside each package.

## Rules

- Keep the layering in `docs/ARCHITECTURE.md` — the CI architecture
  test fails on violations.
- API changes start in `docs/api.yaml`, then client + server together.
- Visual changes go through `DraqosTokens` in `draqos_ui`.
- Never commit secrets. Use `GITHUB_TOKEN` from the environment only.
- Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, ...).
- Add/extend tests for every behavior change; QR render changes must
  keep the `zxing2` decode tests green.
