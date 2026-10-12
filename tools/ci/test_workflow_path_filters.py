"""Regression tests for GitHub Actions path filters.

Uses only Python's standard library, so the inexpensive website CI can
detect a drift that accidentally restores full Dart/Android runs for README.
The test asserts routing, not GitHub's branch-protection configuration.
"""

import fnmatch
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"


def event_patterns(filename: str, event: str, kind: str) -> list[str]:
    """Read simple on.<event>.paths[-ignore] lists without a YAML dependency."""
    lines = (WORKFLOWS / filename).read_text(encoding="utf-8").splitlines()
    in_on = False
    current_event = None
    current_kind = None
    found = []

    for line in lines:
        if line == "on:":
            in_on = True
            continue
        if not in_on:
            continue
        if line and not line[0].isspace() and not line.startswith("#"):
            break
        if line.startswith("  ") and not line.startswith("    "):
            current_event = line[2:].removesuffix(":")
            current_kind = None
            continue
        if current_event != event:
            continue
        if line.startswith("    ") and not line.startswith("      "):
            current_kind = line[4:].removesuffix(":")
            continue
        if current_kind == kind and line.startswith("      - "):
            found.append(line[8:].strip("'\""))

    return found


def matches(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in patterns)


def triggers_expensive(filename: str, event: str, changed: list[str]) -> bool:
    ignored = event_patterns(filename, event, "paths-ignore")
    if not ignored:
        raise AssertionError(f"Missing paths-ignore: {filename}, {event}")
    return any(not matches(path, ignored) for path in changed)


class WorkflowPathFilterTests(unittest.TestCase):
    def test_readme_only_skips_dart_and_android_for_push_and_pr(self):
        for filename in ("test.yaml", "test-release.yaml"):
            for event in ("push", "pull_request"):
                with self.subTest(filename=filename, event=event):
                    self.assertFalse(triggers_expensive(filename, event, ["README.md"]))

    def test_readme_and_other_docs_still_skip_heavy_jobs(self):
        for filename in ("test.yaml", "test-release.yaml"):
            with self.subTest(filename=filename):
                self.assertFalse(
                    triggers_expensive(
                        filename,
                        "pull_request",
                        ["README.md", "ROADMAP.md", "docs/AI_SESSION_STATE.md"],
                    )
                )

    def test_mixed_readme_and_source_still_runs_both_heavy_jobs(self):
        for filename in ("test.yaml", "test-release.yaml"):
            for event in ("push", "pull_request"):
                with self.subTest(filename=filename, event=event):
                    self.assertTrue(
                        triggers_expensive(filename, event, ["README.md", "lib/main.dart"])
                    )
                    self.assertTrue(
                        triggers_expensive(filename, event, [".github/workflows/test.yaml"])
                    )

    def test_test_only_changes_keep_dart_and_skip_android(self):
        self.assertTrue(
            triggers_expensive("test.yaml", "pull_request", ["test/ui/sample_test.dart"])
        )
        self.assertFalse(
            triggers_expensive(
                "test-release.yaml", "pull_request", ["test/ui/sample_test.dart"]
            )
        )

    def test_readme_gets_lightweight_docs_validation_but_no_pages_deploy(self):
        docs = event_patterns("test-deploy-docs.yaml", "pull_request", "paths")
        pages = event_patterns("deploy-docs.yaml", "push", "paths")
        self.assertIn("README.md", docs)
        self.assertIn("tools/ci/test_workflow_path_filters.py", docs)
        self.assertTrue(matches("README.md", docs))
        self.assertFalse(matches("README.md", pages))
        self.assertTrue(matches("website/docs/help/privacy.mdx", docs))


if __name__ == "__main__":
    unittest.main()
