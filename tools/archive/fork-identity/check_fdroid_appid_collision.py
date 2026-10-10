#!/usr/bin/env python3
"""Check whether an Android Application ID already exists in fdroiddata metadata.

The check is intentionally local and deterministic: point it at a checked-out
fdroiddata repository. It does not perform network requests, mutate either
repository, or attempt to infer whether a similarly named app is related.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

APPLICATION_ID_RE = re.compile(r"^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+$")
METADATA_SUFFIXES = (".yml", ".yaml", ".txt")


def validate_application_id(application_id: str) -> str:
    candidate = application_id.strip()
    if not APPLICATION_ID_RE.fullmatch(candidate):
        raise ValueError(
            "Application ID must contain at least two lowercase dot-separated "
            "segments using letters, digits, or underscores."
        )
    return candidate


def metadata_directory(fdroiddata_root: Path) -> Path:
    root = fdroiddata_root.resolve()
    metadata = root / "metadata"
    if not metadata.is_dir():
        raise ValueError(
            f"fdroiddata metadata directory not found: {metadata}. "
            "Pass the root of a checked-out fdroiddata repository."
        )
    return metadata


def find_collisions(fdroiddata_root: Path, application_id: str) -> tuple[Path, ...]:
    candidate = validate_application_id(application_id)
    metadata = metadata_directory(fdroiddata_root)
    matches = [metadata / f"{candidate}{suffix}" for suffix in METADATA_SUFFIXES]
    return tuple(path for path in matches if path.is_file())


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Check a proposed Android Application ID against a local fdroiddata "
            "metadata checkout."
        )
    )
    parser.add_argument("--application-id", required=True)
    parser.add_argument(
        "--fdroiddata-root",
        required=True,
        type=Path,
        help="Path to a checked-out fdroiddata repository.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        candidate = validate_application_id(args.application_id)
        collisions = find_collisions(args.fdroiddata_root, candidate)
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    if collisions:
        print(f"COLLISION: {candidate} already exists in fdroiddata metadata:")
        for path in collisions:
            print(f"  {path}")
        return 2

    print(f"CLEAR: {candidate} is not present in fdroiddata metadata.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
