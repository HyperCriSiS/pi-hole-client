#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import tempfile
import unittest
import sys
from pathlib import Path

SCRIPT = Path(__file__).with_name("migrate_android_identity.py")
SPEC = importlib.util.spec_from_file_location("migrate_android_identity", SCRIPT)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = module
SPEC.loader.exec_module(module)

OLD_ID = "io.github.tsutsu3.pi_hole_client"
NEW_ID = "io.github.example.pihole_client"


class AndroidIdentityMigratorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self._write_fixture()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _write(self, path: str, content: str) -> None:
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def _write_fixture(self) -> None:
        self._write(
            "tools/identity/android-identity.env",
            "\n".join(
                [
                    f"ANDROID_APPLICATION_ID='{OLD_ID}'",
                    "ANDROID_APP_LABEL='Pi-hole client'",
                    "ANDROID_RESOURCE_APP_NAME='Pi-hole'",
                    "ANDROID_FORBIDDEN_APPLICATION_IDS=''",
                    "",
                ]
            ),
        )
        self._write(
            "android/app/build.gradle",
            f'''android {{\n    namespace = "{OLD_ID}"\n    defaultConfig {{\n        applicationId = "{OLD_ID}"\n    }}\n}}\n''',
        )
        self._write(
            "android/app/src/main/AndroidManifest.xml",
            f'''<application android:label="Pi-hole client">\n'
                f'  <action android:name="{OLD_ID}.widget.REFRESH"/>\n'
                f'  <action android:name="{OLD_ID}.widget.TOGGLE"/>\n'
                '</application>\n''',
        )
        self._write(
            "android/app/src/main/res/values/strings.xml",
            '<resources>\n  <string name="app_name">Pi-hole</string>\n</resources>\n',
        )
        self._write(
            ".github/workflows/test-release.yaml",
            f"with:\n  packageName: {OLD_ID}\n",
        )

        old_path = OLD_ID.replace(".", "/")
        self._write(
            f"android/app/src/main/kotlin/{old_path}/MainActivity.kt",
            f"package {OLD_ID}\n\nclass MainActivity\n",
        )
        self._write(
            f"android/app/src/main/kotlin/{old_path}/widget/WidgetConstants.kt",
            "\n".join(
                [
                    f"package {OLD_ID}.widget",
                    "",
                    "object WidgetConstants {",
                    f'  const val ACTION_REFRESH = "{OLD_ID}.widget.REFRESH"',
                    f'  const val ACTION_TOGGLE = "{OLD_ID}.widget.TOGGLE"',
                    "}",
                    "",
                ]
            ),
        )
        self._write(
            f"android/app/src/test/kotlin/{old_path}/WidgetTest.kt",
            f"package {OLD_ID}\n\nclass WidgetTest\n",
        )

    def requested_identity(self):
        return module.Identity(NEW_ID, "Fork client", "Fork", ())

    def test_plan_is_dry_and_records_all_required_surfaces(self) -> None:
        plan = module.plan_migration(self.root, self.requested_identity())

        self.assertGreaterEqual(len(plan.writes), 5)
        self.assertEqual(len(plan.moves), 3)
        self.assertTrue(
            (self.root / f"android/app/src/main/kotlin/{OLD_ID.replace('.', '/')}/MainActivity.kt").exists()
        )
        config = (self.root / "tools/identity/android-identity.env").read_text()
        self.assertIn(OLD_ID, config)
        self.assertNotIn(NEW_ID, config)

    def test_apply_moves_kotlin_and_preserves_legacy_id_only_as_forbidden(self) -> None:
        plan = module.plan_migration(self.root, self.requested_identity())
        module.apply_plan(self.root, plan)

        new_path = NEW_ID.replace(".", "/")
        old_path = OLD_ID.replace(".", "/")
        self.assertFalse(
            (self.root / f"android/app/src/main/kotlin/{old_path}/MainActivity.kt").exists()
        )
        moved = self.root / f"android/app/src/main/kotlin/{new_path}/MainActivity.kt"
        self.assertTrue(moved.exists())
        self.assertIn(f"package {NEW_ID}", moved.read_text())

        widget = self.root / f"android/app/src/main/kotlin/{new_path}/widget/WidgetConstants.kt"
        self.assertIn(f"{NEW_ID}.widget.REFRESH", widget.read_text())
        self.assertNotIn(OLD_ID, widget.read_text())

        config = (self.root / "tools/identity/android-identity.env").read_text()
        self.assertIn(f"ANDROID_APPLICATION_ID={NEW_ID}", config)
        self.assertIn(f"ANDROID_FORBIDDEN_APPLICATION_IDS={OLD_ID}", config)

        runtime_files = [
            self.root / "android/app/build.gradle",
            self.root / "android/app/src/main/AndroidManifest.xml",
            self.root / ".github/workflows/test-release.yaml",
            moved,
            widget,
        ]
        for path in runtime_files:
            self.assertNotIn(OLD_ID, path.read_text(), str(path))

    def test_invalid_application_id_is_rejected_before_writes(self) -> None:
        requested = module.Identity("Example Invalid", "Fork", "Fork", ())
        with self.assertRaises(ValueError):
            module.plan_migration(self.root, requested)

        self.assertIn(
            OLD_ID,
            (self.root / "android/app/build.gradle").read_text(),
        )


if __name__ == "__main__":
    unittest.main()
