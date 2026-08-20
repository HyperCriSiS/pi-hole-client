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
flutter build apk --release
```

The CI source-build job pins the currently supported build environment to
Java 17 and Flutter 3.44.1 and verifies that the produced release APK is
unsigned.

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

`mobile_scanner` currently uses Google ML Kit for Android. That is incompatible
with the goal of an F-Droid-main-repository build that contains only acceptable
free dependencies.

The QR token scanner is isolated to
`lib/ui/core/ui/modals/scan_token_modal.dart`, so the planned fix is to replace
that Android scanner dependency with a FLOSS ZXing-based implementation while
preserving the current permission flow and token callback behavior.

### Package identity for this maintenance fork

This repository currently preserves the upstream Android application ID
`io.github.tsutsu3.pi_hole_client`.

If this maintenance fork is submitted as an independent application rather than
as continuation/packaging work for the upstream application, current F-Droid
policy requires a distinct application ID and corresponding name/branding.
That identity decision must be made before proposing downstream `fdroiddata`
metadata for an independent fork.

## Validation checklist

- [x] Secret-free `.env` input is available via `.env.sample`.
- [x] Release signing is optional for clean source builds.
- [x] Signed release builds still require the complete existing signing config.
- [ ] Unsigned source-build CI passes on `dev`.
- [ ] Google ML Kit is removed from the Android QR-scanner path.
- [ ] QR token scanning has focused regression coverage after the scanner swap.
- [ ] Package identity/submission ownership is resolved.
- [ ] Downstream F-Droid metadata is drafted and validated against the chosen
      immutable release commit.
