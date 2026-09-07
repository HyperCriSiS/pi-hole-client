# Android package identity migration

Issue #134 requires an independent F-Droid submission of this maintenance fork to use its own Android identity. The current repository deliberately still uses the upstream identity until a new product identity is chosen.

## Current baseline

The canonical values are stored in `tools/identity/android-identity.env`:

- Android application ID / Gradle namespace: `io.github.tsutsu3.pi_hole_client`
- Android manifest label: `Pi-hole client`
- Android `app_name` resource: `Pi-hole`

The audit is intentionally separate from the branding decision. It makes the rename mechanically checkable without inventing an application ID, name, or icon.

Run the current baseline check with:

```bash
bash tools/identity/audit_android_identity.sh
```

The unsigned Android PR build runs the same audit before installing Flutter/Java dependencies, so mixed identity state fails early and cheaply.

## Migration surface

A dedicated identity migration must update these areas together:

1. `android/app/build.gradle`
   - `namespace`
   - `applicationId`
2. Kotlin package declarations and directory paths under:
   - `android/app/src/main/kotlin`
   - `android/app/src/debug/kotlin`
   - `android/app/src/release/kotlin`
   - `android/app/src/test/kotlin`
   - this includes the home-widget implementation and its native tests
3. `android/app/src/main/AndroidManifest.xml`
   - application label
   - package-prefixed widget broadcast actions
4. `android/app/src/main/res/values/strings.xml`
   - Android display strings such as `app_name`
5. launcher/branding assets
   - adaptive icon XML
   - `mipmap-*` launcher PNGs
   - `drawable-*` launcher foregrounds
   - splash/other branded images must be reviewed as part of the branding pass
6. `.github/workflows/test-release.yaml`
   - Google Play `packageName`
   - artifact naming should be reviewed when the product name changes
7. shared Flutter/package metadata such as `pubspec.yaml` and user-facing translated strings must be reviewed for the selected product name.
8. downstream `fdroiddata` metadata is drafted only after the repository identity is final.

## Dedicated rename procedure

Do not perform a partial rename.

1. Choose the independent fork's application ID, product name, icon, and translated naming.
2. Update `tools/identity/android-identity.env` to the new canonical values.
3. Move every Kotlin source/test directory to the path corresponding to the new package and update each `package` declaration.
4. Update Gradle, manifest actions/label, Android strings/assets, release metadata, and shared user-facing branding.
5. Put the previous application ID in `ANDROID_FORBIDDEN_APPLICATION_IDS` in `tools/identity/android-identity.env`.
6. Run:

```bash
bash tools/identity/audit_android_identity.sh
flutter pub get
cp .env.sample .env
dart run tools/generate_git_commit.dart
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter build apk --release
```

7. Review the app launcher, splash screen, widget setup/refresh/toggle/open actions, upgrade/install behavior, and store-facing identity on a real Android device.
8. Only after those checks pass, draft the downstream F-Droid metadata for the new application ID.

`ANDROID_FORBIDDEN_APPLICATION_IDS` is a regression guard: after the rename, the audit searches Android runtime/configuration files and release workflows for the legacy ID so a stale widget action, package declaration, or store package cannot silently survive.
