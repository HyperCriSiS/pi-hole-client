# Archived independent-fork Android identity tools

**Status: parked / manual only.** These tools exist solely for a possible future **independent fork** of Pi-hole Client. No fork app ID, branding, or separate F-Droid submission has been approved; do not run a migration on the maintained upstream identity. Retained for reproducibility, not active development.

Do **not** confuse these with the active F-Droid source-build helper at `tools/prepare_fdroid_source_build.dart`, which must remain part of Android release validation.

## Tools

- `audit_android_identity.sh`: manual validation of package, Kotlin, widget action, and release wiring consistency.
- `migrate_android_identity.py`: reviewable dry-run-by-default package migration. `--apply` modifies repository files **only after a product decision**.
- `check_fdroid_appid_collision.py`: optional local collision check against a checked-out `fdroiddata/metadata` directory.
- `android-identity.env`: current reference identity. Keep aligned if the core project identity legitimately changes.
- `test_*.py`: retained unit/regression tests for the parked helpers.

Run archive tests only when changing these scripts or reactivating independent-fork publication:

```bash
python3 tools/archive/fork-identity/test_migrate_android_identity.py
python3 tools/archive/fork-identity/test_check_fdroid_appid_collision.py
bash tools/archive/fork-identity/audit_android_identity.sh
```

The automated PR build no longer runs these tools. They do not validate an Android source build and are not part of a normal upstream/F-Droid integration. If independent distribution is approved, restore appropriate checks in CI **after** adapting the tooling to current Android/Flutter versions and testing the migration on a temporary branch.
