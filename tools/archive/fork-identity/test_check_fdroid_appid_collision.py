#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import tempfile
import unittest
import sys
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).with_name("check_fdroid_appid_collision.py")
SPEC = importlib.util.spec_from_file_location("check_fdroid_appid_collision", SCRIPT)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = module
SPEC.loader.exec_module(module)

CANDIDATE = "io.github.example.pihole_client"


class FdroidAppIdCollisionCheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        (self.root / "metadata").mkdir()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def test_clear_candidate_has_no_collision(self) -> None:
        self.assertEqual(module.find_collisions(self.root, CANDIDATE), ())

    def test_existing_yaml_metadata_is_reported(self) -> None:
        collision = self.root / "metadata" / f"{CANDIDATE}.yml"
        collision.write_text("Categories:\n  - System\n", encoding="utf-8")

        self.assertEqual(module.find_collisions(self.root, CANDIDATE), (collision,))

    def test_legacy_metadata_suffixes_are_also_detected(self) -> None:
        yaml_collision = self.root / "metadata" / f"{CANDIDATE}.yaml"
        txt_collision = self.root / "metadata" / f"{CANDIDATE}.txt"
        yaml_collision.write_text("Categories: []\n", encoding="utf-8")
        txt_collision.write_text("legacy\n", encoding="utf-8")

        self.assertEqual(
            module.find_collisions(self.root, CANDIDATE),
            (yaml_collision, txt_collision),
        )

    def test_invalid_application_id_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            module.find_collisions(self.root, "Example Invalid")

    def test_missing_metadata_directory_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as empty:
            with self.assertRaises(ValueError):
                module.find_collisions(Path(empty), CANDIDATE)

    def test_cli_returns_two_for_collision(self) -> None:
        (self.root / "metadata" / f"{CANDIDATE}.yml").write_text("Categories: []\n")
        with mock.patch.object(sys, "stdout"):
            result = module.main(
                [
                    "--application-id",
                    CANDIDATE,
                    "--fdroiddata-root",
                    str(self.root),
                ]
            )
        self.assertEqual(result, 2)


if __name__ == "__main__":
    unittest.main()
