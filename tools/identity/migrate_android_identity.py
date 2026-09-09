#!/usr/bin/env python3
"""Plan or apply a complete Android package identity migration.

The command defaults to dry-run mode. Use --apply only after the new product
identity has been chosen. The existing audit_android_identity.sh script is run
after an applied migration unless --skip-audit is explicitly supplied.
"""

from __future__ import annotations

import argparse
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

APPLICATION_ID_RE = re.compile(
    r"^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+$"
)
ENV_VALUE_RE = re.compile(r"^([A-Z0-9_]+)=(?:'([^']*)'|\"([^\"]*)\"|(.*))$")
SOURCE_SETS = ("main", "debug", "release", "test")


@dataclass(frozen=True)
class Identity:
    application_id: str
    app_label: str
    resource_app_name: str
    forbidden_ids: tuple[str, ...]


@dataclass(frozen=True)
class PlannedWrite:
    path: Path
    content: str


@dataclass(frozen=True)
class PlannedMove:
    source: Path
    destination: Path
    content: str


@dataclass(frozen=True)
class MigrationPlan:
    writes: tuple[PlannedWrite, ...]
    moves: tuple[PlannedMove, ...]

    @property
    def changed_paths(self) -> tuple[Path, ...]:
        paths = [write.path for write in self.writes]
        for move in self.moves:
            paths.extend((move.source, move.destination))
        return tuple(dict.fromkeys(paths))


def parse_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        match = ENV_VALUE_RE.match(line)
        if not match:
            raise ValueError(f"Unsupported identity config line: {raw_line!r}")
        key, single, double, bare = match.groups()
        values[key] = single if single is not None else double if double is not None else bare.strip()
    return values


def load_identity(config_path: Path) -> Identity:
    values = parse_env(config_path)
    try:
        application_id = values["ANDROID_APPLICATION_ID"]
        app_label = values["ANDROID_APP_LABEL"]
        resource_app_name = values["ANDROID_RESOURCE_APP_NAME"]
    except KeyError as error:
        raise ValueError(f"Missing identity setting: {error.args[0]}") from error
    forbidden = tuple(filter(None, values.get("ANDROID_FORBIDDEN_APPLICATION_IDS", "").split()))
    return Identity(application_id, app_label, resource_app_name, forbidden)


def validate_new_identity(current: Identity, new: Identity) -> None:
    if not APPLICATION_ID_RE.fullmatch(new.application_id):
        raise ValueError(
            "Application ID must contain at least two lowercase dot-separated "
            "segments using letters, digits, or underscores."
        )
    if new.application_id == current.application_id:
        raise ValueError("New application ID must differ from the current ID.")
    if not new.app_label.strip():
        raise ValueError("Android app label must not be empty.")
    if not new.resource_app_name.strip():
        raise ValueError("Android resource app name must not be empty.")
    if new.application_id in new.forbidden_ids:
        raise ValueError("New application ID cannot also be forbidden.")


def replace_exact(text: str, old: str, new: str, *, path: Path, count: int) -> str:
    actual = text.count(old)
    if actual != count:
        raise ValueError(f"{path}: expected {count} occurrence(s) of {old!r}, found {actual}.")
    return text.replace(old, new)


def replace_regex_once(text: str, pattern: str, replacement: str, *, path: Path) -> str:
    result, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise ValueError(f"{path}: expected one match for {pattern!r}, found {count}.")
    return result


def update_env_text(current_text: str, current: Identity, new: Identity, path: Path) -> str:
    updated = current_text
    replacements = {
        "ANDROID_APPLICATION_ID": new.application_id,
        "ANDROID_APP_LABEL": new.app_label,
        "ANDROID_RESOURCE_APP_NAME": new.resource_app_name,
        "ANDROID_FORBIDDEN_APPLICATION_IDS": " ".join(new.forbidden_ids),
    }
    for key, value in replacements.items():
        pattern = rf"^{re.escape(key)}=.*$"
        replacement = f"{key}={shlex.quote(value)}"
        updated = replace_regex_once(updated, pattern, replacement, path=path)
    return updated


def plan_migration(repo_root: Path, new_identity: Identity) -> MigrationPlan:
    repo_root = repo_root.resolve()
    config = repo_root / "tools/identity/android-identity.env"
    if not config.is_file():
        raise ValueError(f"Identity config not found: {config}")

    current = load_identity(config)
    forbidden = tuple(dict.fromkeys((*current.forbidden_ids, current.application_id)))
    new_identity = Identity(
        new_identity.application_id,
        new_identity.app_label,
        new_identity.resource_app_name,
        forbidden,
    )
    validate_new_identity(current, new_identity)

    writes: list[PlannedWrite] = []
    moves: list[PlannedMove] = []

    gradle = repo_root / "android/app/build.gradle"
    text = gradle.read_text(encoding="utf-8")
    text = replace_exact(
        text,
        f'namespace = "{current.application_id}"',
        f'namespace = "{new_identity.application_id}"',
        path=gradle,
        count=1,
    )
    text = replace_exact(
        text,
        f'applicationId = "{current.application_id}"',
        f'applicationId = "{new_identity.application_id}"',
        path=gradle,
        count=1,
    )
    writes.append(PlannedWrite(gradle, text))

    manifest = repo_root / "android/app/src/main/AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    text = replace_exact(
        text,
        f'android:label="{current.app_label}"',
        f'android:label="{new_identity.app_label}"',
        path=manifest,
        count=1,
    )
    widget_action_count = text.count(f'{current.application_id}.widget.')
    if widget_action_count == 0:
        raise ValueError(f"{manifest}: no package-prefixed widget actions found.")
    text = text.replace(
        f'{current.application_id}.widget.',
        f'{new_identity.application_id}.widget.',
    )
    writes.append(PlannedWrite(manifest, text))

    strings = repo_root / "android/app/src/main/res/values/strings.xml"
    text = strings.read_text(encoding="utf-8")
    pattern = r'(<string name="app_name">)([^<]*)(</string>)'
    match = re.search(pattern, text)
    if not match or match.group(2) != current.resource_app_name:
        found = match.group(2) if match else "<missing>"
        raise ValueError(
            f"{strings}: current app_name is {found!r}; expected {current.resource_app_name!r}."
        )
    text = re.sub(
        pattern,
        lambda m: f"{m.group(1)}{new_identity.resource_app_name}{m.group(3)}",
        text,
        count=1,
    )
    writes.append(PlannedWrite(strings, text))

    release_workflow = repo_root / ".github/workflows/test-release.yaml"
    text = release_workflow.read_text(encoding="utf-8")
    text = replace_regex_once(
        text,
        rf"^(\s*packageName:\s*){re.escape(current.application_id)}(\s*)$",
        rf"\g<1>{new_identity.application_id}\g<2>",
        path=release_workflow,
    )
    writes.append(PlannedWrite(release_workflow, text))

    old_path = Path(*current.application_id.split("."))
    new_path = Path(*new_identity.application_id.split("."))
    kotlin_files = 0
    destination_paths: set[Path] = set()

    for source_set in SOURCE_SETS:
        kotlin_root = repo_root / f"android/app/src/{source_set}/kotlin"
        if not kotlin_root.is_dir():
            continue
        source_package_root = kotlin_root / old_path
        if not source_package_root.is_dir():
            existing = list(kotlin_root.rglob("*.kt"))
            if existing:
                raise ValueError(
                    f"{kotlin_root}: Kotlin sources exist but current package root "
                    f"{source_package_root.relative_to(repo_root)} is missing."
                )
            continue

        for source in sorted(source_package_root.rglob("*.kt")):
            kotlin_files += 1
            relative = source.relative_to(source_package_root)
            destination = kotlin_root / new_path / relative
            if destination in destination_paths or (destination.exists() and destination != source):
                raise ValueError(f"Kotlin destination already exists: {destination}")
            destination_paths.add(destination)

            content = source.read_text(encoding="utf-8")
            package_matches = re.findall(
                rf"^package\s+{re.escape(current.application_id)}(?:\.[A-Za-z0-9_.]+)?\s*$",
                content,
                flags=re.MULTILINE,
            )
            if len(package_matches) != 1:
                raise ValueError(
                    f"{source}: expected exactly one package declaration rooted at "
                    f"{current.application_id}, found {len(package_matches)}."
                )
            content = content.replace(current.application_id, new_identity.application_id)
            moves.append(PlannedMove(source, destination, content))

    if kotlin_files == 0:
        raise ValueError("No Kotlin files found under the current Android package path.")

    config_text = config.read_text(encoding="utf-8")
    writes.append(
        PlannedWrite(
            config,
            update_env_text(config_text, current, new_identity, config),
        )
    )

    planned_text = "\n".join(write.content for write in writes)
    planned_text += "\n" + "\n".join(move.content for move in moves)
    if current.application_id in planned_text:
        raise ValueError(
            "Planned runtime/release identity files still contain the legacy application ID."
        )

    return MigrationPlan(tuple(writes), tuple(moves))


def apply_plan(repo_root: Path, plan: MigrationPlan) -> None:
    for write in plan.writes:
        write.path.write_text(write.content, encoding="utf-8")

    for move in plan.moves:
        move.destination.parent.mkdir(parents=True, exist_ok=True)
        move.destination.write_text(move.content, encoding="utf-8")

    for move in plan.moves:
        move.source.unlink()

    android_root = repo_root / "android/app/src"
    for directory in sorted(android_root.rglob("*"), reverse=True):
        if directory.is_dir():
            try:
                directory.rmdir()
            except OSError:
                pass


def run_audit(repo_root: Path) -> None:
    subprocess.run(
        ["bash", "tools/identity/audit_android_identity.sh"],
        cwd=repo_root,
        check=True,
    )


def relative(repo_root: Path, path: Path) -> str:
    return str(path.resolve().relative_to(repo_root.resolve()))


def print_plan(repo_root: Path, plan: MigrationPlan) -> None:
    print("Android identity migration plan:")
    for write in plan.writes:
        print(f"  UPDATE {relative(repo_root, write.path)}")
    for move in plan.moves:
        print(
            f"  MOVE   {relative(repo_root, move.source)} -> "
            f"{relative(repo_root, move.destination)}"
        )
    print(f"Planned changes: {len(plan.changed_paths)} path(s)")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Plan or apply the mechanically auditable Android package identity migration."
    )
    parser.add_argument("--application-id", required=True)
    parser.add_argument("--app-label", required=True)
    parser.add_argument("--resource-app-name", required=True)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write the migration. Without this flag the command is a dry run.",
    )
    parser.add_argument(
        "--skip-audit",
        action="store_true",
        help=argparse.SUPPRESS,
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help=argparse.SUPPRESS,
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    repo_root = args.repo_root.resolve()
    requested = Identity(
        args.application_id.strip(),
        args.app_label.strip(),
        args.resource_app_name.strip(),
        (),
    )

    try:
        plan = plan_migration(repo_root, requested)
        print_plan(repo_root, plan)
        if not args.apply:
            print("Dry run only. Re-run with --apply after reviewing the selected identity.")
            return 0

        apply_plan(repo_root, plan)
        if not args.skip_audit:
            run_audit(repo_root)
        print("Android identity migration applied successfully.")
        print("Branding assets and translated/user-facing product strings still require review.")
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
