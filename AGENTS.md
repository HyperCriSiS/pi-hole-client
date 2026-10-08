# Agent instructions

Read [`ROADMAP.md`](ROADMAP.md) for the authoritative project roadmap, [`docs/AI_SESSION_STATE.md`](docs/AI_SESSION_STATE.md) for the latest recorded handoff, and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for architectural context before planning changes.

Keep the authoritative roadmap at the repository root; `docs/ROADMAP.md` is a stable pointer, not a second copy. Preserve existing links and avoid moving documentation without updating all consumers.

Base each change on the current `main`, work in a task-specific branch, and integrate through a pull request. Run the applicable Dart/Flutter tests, dependency resolution and Android build checks; check CI results on the exact commit before merging. Do not treat a green check on an earlier commit as proof for a changed head.

Verify dependency upgrades against the Flutter/Dart SDK constraints and native platform support. Do not force incompatible transitive dependencies or bypass failing CI. Keep credential and diagnostic redaction behavior intact.

Do not delete protected development branches, investigation branches, or other branches with potentially unmerged work. Confirm branch history and the disposition of any related pull request before cleanup.
