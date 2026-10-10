# DRAQOS agent rules (AGENTS.md)

This repo is built autonomously in milestones; human input only when
truly blocked. Decisions go to `docs/DECISIONS.md`.

1. **Architecture first**: dependencies flow toward `draqos_core`.
   Never import client/server/http from `ui`/`render`; never import
   Flutter from `core`. `dart tool/check_architecture.dart` must pass.
2. **One API contract**: `docs/api.yaml` (OpenAPI). Client and server
   must match it; change the YAML first, then both sides.
3. **Design tokens only**: all visuals via `DraqosTokens`. No native
   button/card look anywhere; Sci-Fi Game GUI painted with
   CustomPainter/shaders.
4. **Privacy**: scan counters store timestamps only — no IPs, no
   personal data. Admin API is never exposed publicly (only `/r/<id>`).
5. **Commits**: small, Conventional Commits, one per milestone minimum.
   Push at the end of each milestone.
6. **Token hygiene**: read `GITHUB_TOKEN` only from the environment.
   Never write it to files, logs, commits or remote URLs.
7. **Verify each milestone**: `dart format`, `dart analyze`,
   package tests, architecture check — before committing.
