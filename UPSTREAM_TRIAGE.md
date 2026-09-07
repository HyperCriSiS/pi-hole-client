# Upstream Triage

This document tracks upstream issues/PRs that affect the maintenance fork and records whether they are imported, reworked, held, or already addressed locally.

## Dependency / build maintenance

| Upstream | Topic | Fork status | Notes |
|---|---|---|---|
| #660 | Dart/Flutter dependency group update | Imported with compatibility adjustment | Upstream test job passes and the dependency group was imported through fork PR #1 and is integrated into `main`. The later F-Droid Android release-build gate showed that `flutter_secure_storage` 11.x and `permission_handler` 13.x require compileSdk 37, so those two direct dependencies are intentionally constrained to the last Android-36-compatible majors while the rest of the imported update remains. |
| #659 | actions/setup-node v6 -> v7 | Imported | Applied directly to both docs workflows. Upstream test/deploy checks pass; upstream Sonar is unrelated/failing. |
| #646 | TLS certificate inspection/cache refactor | Hold / rework | Upstream PR is still a draft, based on an older `main`, with coverage gates failing. Do not merge wholesale. Rebase/rework before adoption. |
| #484 | ESLint 8 -> 9 | Hold / fix first | Upstream website deployment check fails. Requires ESLint/Docusaurus compatibility work before import. |

## Live Log reliability

| Upstream | Topic | Fork status | Notes |
|---|---|---|---|
| #647 | Live Log watchdog / stale stream recovery | Implemented locally | Watchdog/reconnect behavior is in the fork with regression coverage. |
| #648 | Live Log filtering cleanup | Implemented locally | Filtering/state cleanup was integrated with the watchdog work. |

## Pi-hole v6 API / feature work

| Upstream | Topic | Fork status | Notes |
|---|---|---|---|
| #639 | Generated Pi-hole v6 client migration | **Active / bounded.** Generated-client migration is integrated behind the adapter seam and the snapshot is reproducibly refreshed to pinned FTL v6.7 (`fa65a88f8cdef1013594d4de14108077954faea4`) with pinned Redocly/OpenAPI Generator tooling. The remaining handwritten paths were re-audited against v6.7 and remain explicit compatibility/schema/encoding holds rather than unreviewed migration work. |
| #570 | Local CNAME management | **Implemented in `main`.** v6 repository/domain/UI support is present with TTL preservation and regression coverage. v5 remains unsupported because its Local DNS path does not expose equivalent capability. |
| #352 | v6 server-side log filtering | Hold | Performance feature; overlaps generated v6 migration. Keep v5 local filtering. |

## Deterministic UI / behavior fixes

| Upstream | Topic | Fork status | Notes |
|---|---|---|---|
| #604 | UI cleanup | Implemented | Deterministic UI cleanup imported/validated. |
| #404 | Translation docs | **Implemented in `main`**. Added `docs/translations.md` documenting ARB-based translation contributions and the process for adding new locales. |
| #397 | Windows LocalDNS suggestions | **Implemented and CI-validated in `main`**. `TextFieldTapRegion` keeps suggestion-list mouse interaction inside the field tap group while outside clicks still dismiss; focused regression tests cover both behaviors. |
| #442 | Android 16 popup-menu crash | Device reproduction required | Old v1.7.0 stack is insufficient to justify a current lifecycle change; reproduce on Android 16/current `main` first. |
| #636 | Empty Network tab after long-running use | Device reproduction required | Soak/reproduce on current dependencies and capture logs before changing state/repository behavior. |
| #598 | Logout/back-loop | Device reproduction required | Reproduce repeated logout/back-stack sequence before altering navigation. |
| #501 | Widget display/configuration | Device reproduction required | Validate real widget resize/layout states first. |
| #293 | Android auth/secure-storage crash | Current `main` deliberately remains on `flutter_secure_storage` 10.x because 11.x requires compileSdk 37 while the project is on 36. Re-test affected Galaxy devices and migration from older app versions before considering resolved; do not conflate that device validation with the F-Droid build-compatibility pin. |
| #178 | App Lock after passcode removal | **Implemented in `main` (`cc501770`, tests `e6bb9311`)**. Removing the passcode now immediately unlocks the in-memory app state, and loading persisted config synchronizes the lock state with whether a passcode actually exists. |
| #134 | F-Droid | **In progress in `main`.** Secret-free unsigned Android packaging is isolated from private release signing. `mobile_scanner`/Google ML Kit has been removed and replaced by `camera` + pure-Dart `zxing2`; the F-Droid source-build checkout also switches `sqlite3` to Android system SQLite so it does not fetch a precompiled native library during the build. The download-free unsigned build and `apksigner` unsigned-artifact verification are CI-validated on `3d3e3d74`. The Android identity migration surface is now inventoried and guarded in the existing unsigned PR build (Gradle ID/namespace, Kotlin package paths, widget actions, display strings/assets, and release metadata). F-Droid policy still requires choosing and applying a fresh Android ID plus corresponding name/icon/string changes for an independent submission, so the actual package identity remains the final product-level gate before downstream `fdroiddata` metadata. |

## Priority order

1. Live Log watchdog + dependency update (implemented in `main`).
2. #432 and #622 (implemented); #592/#593 verified as already addressed in current code.
3. #632 diagnostics and #178 App Lock (implemented in `main`).
4. Deterministic UI/docs work (#604, #404, #638, #397) is implemented and validated; #442 is the remaining Phase 1 item and requires a fresh Android 16 reproduction before any lifecycle change.
5. Reproduce/fix device-dependent #636, #598, #501 and #293 on current dependencies.
6. #639/#352: incremental generated-v6 migration remains active on `main`; the generated snapshot is reproducibly pinned to FTL v6.7 and the remaining handwritten paths have been re-audited as explicit compatibility/schema/encoding holds. #570 is complete. #134 source-build work is CI-validated but downstream submission remains blocked on the required independent-fork package identity.
