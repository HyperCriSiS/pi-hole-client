# F-Droid source-build readiness

This repository keeps the normal signed release path and the F-Droid/source-build
path separate.

## Source build without private signing material

A clean checkout does not need a private Android keystore to build the release
APK. `android/app/build.gradle` configures release signing only when
`android/key.properties` exists. When that file is present, all four release
signing properties remain required and the existing signed GitHub release path
continues to use them.

For a non-secret source build:

```bash
cp .env.sample .env
flutter pub get
dart run tools/generate_git_commit.dart
dart run tools/prepare_fdroid_source_build.dart
flutter build apk --release
```

The CI source-build job pins the currently supported build environment to
Java 17 and Flutter 3.44.1 and verifies that the produced release APK is
unsigned. This path was validated on `3d3e3d74`: both the release build and
the `apksigner` unsigned-artifact check completed successfully. `tools/prepare_fdroid_source_build.dart` modifies only that ephemeral
source-build checkout so the `sqlite3` native-asset hook uses Android system
SQLite instead of downloading a precompiled `.so` from a GitHub release. The
normal signed release path and Windows/Linux FFI builds keep their existing
bundled SQLite behavior.

The project stays on Android compileSdk 36 for this work. The direct
`flutter_secure_storage` and `permission_handler` constraints are therefore kept
on their last compatible majors rather than coupling F-Droid readiness to an
unrelated compileSdk/AGP 37 migration.

`.env.sample` deliberately disables Sentry and contains no deployment secrets.

## Where F-Droid metadata belongs

The metadata used by the official F-Droid repository is maintained downstream
in the F-Droid `fdroiddata` repository. This application repository should
therefore contain build-readiness documentation and source changes, not pretend
that an in-repository metadata file has already been accepted by F-Droid.

A downstream build entry should be proposed only after all eligibility blockers
below are resolved and should reference an immutable commit.

## Remaining eligibility blockers

### Android QR scanner

The previous Android `mobile_scanner` path and its Google ML Kit dependency have
been removed. QR token import now uses Flutter `camera` for frames and the
pure-Dart `zxing2` decoder. The public `ScanTokenModal` behavior and focused
callback regression coverage are preserved, so the scanner swap does not change
the token-import contract.

### Package identity for this maintenance fork

This repository currently preserves the upstream Android application ID
`io.github.tsutsu3.pi_hole_client`.

The current F-Droid inclusion policy explicitly requires forked applications to
use a fresh Android Application ID and corresponding name, icon and string
changes, including translation adjustments. For this repository that is not a
one-line Gradle edit: the upstream package is also the Kotlin package tree for
`MainActivity`, widgets, debug/release variants and Android tests, and the Google
Play/release workflow still references the upstream ID.

That identity decision must therefore be handled as a dedicated migration before
proposing downstream `fdroiddata` metadata for an independent fork. This
document intentionally does not invent the new product name or package ID.

## Validation checklist

- [x] Secret-free `.env` input is available via `.env.sample`.
- [x] Release signing is optional for clean source builds.
- [x] Signed release builds still require the complete existing signing config.
- [x] Unsigned source-build CI passes on `dev` (`3d3e3d74`).
- [x] Google ML Kit is removed from the Android QR-scanner path.
- [x] QR token scanning has focused regression coverage after the scanner swap.
- [x] The F-Droid source-build path avoids `sqlite3` precompiled-binary downloads.
- [x] Android-36-compatible dependency majors are explicitly constrained.
- [ ] Package identity/submission ownership is resolved.
- [ ] Downstream F-Droid metadata is drafted and validated against the chosen
      immutable release commit.
