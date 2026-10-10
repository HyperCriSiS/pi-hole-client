# Agent instructions

Read [`ROADMAP.md`](ROADMAP.md) for the authoritative project roadmap, [`docs/AI_SESSION_STATE.md`](docs/AI_SESSION_STATE.md) for the latest recorded handoff, and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for architectural context before planning changes.

Keep the authoritative roadmap at the repository root; `docs/ROADMAP.md` is a stable pointer, not a second copy. Preserve existing links and avoid moving documentation without updating all consumers.

Base each change on the current `main`, work in a task-specific branch, and integrate through a pull request. Run the applicable Dart/Flutter tests, dependency resolution and Android build checks; check CI results on the exact commit before merging. Do not treat a green check on an earlier commit as proof for a changed head.

Verify dependency upgrades against the Flutter/Dart SDK constraints and native platform support. Do not force incompatible transitive dependencies or bypass failing CI. Keep credential and diagnostic redaction behavior intact.

Do not delete protected development branches, investigation branches, or other branches with potentially unmerged work. Confirm branch history and the disposition of any related pull request before cleanup.

Development efficiency: prefer a coherent group of related, low-risk changes per PR (for example several settings screens sharing the same refresh behavior) instead of triggering a full Android build for every identical screen. Keep security, auth, data migrations and unrelated behavior in separate PRs. Use focused tests and quick static checks before pushing; only the final intended HEAD counts for full Dart/Android/CodeQL/Sonar/Codecov validation. Do not repeatedly poll long-running CI jobs or re-run successful workflows unnecessarily; check results at meaningful intervals. For docs-only or test-only changes, preserve existing path-filtered lighter validation. Checkpoint `docs/AI_SESSION_STATE.md` at major milestones, preferably within an already required documentation update; avoid documentation-only micro-PRs for every minor step.

The independent-fork Android identity and F-Droid application-ID helpers are deliberately parked in `tools/archive/fork-identity/` and are excluded from normal CI. Do not revive or extend them absent an explicit decision to publish a separately branded app. Keep the active `tools/prepare_fdroid_source_build.dart`, FLOSS scanner, unsigned Android source APK and artifact checks unchanged.
