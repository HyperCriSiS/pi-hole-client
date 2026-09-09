#!/usr/bin/env python3
"""Percent-encode generated Dart/Dio OpenAPI path parameters.

OpenAPI Generator 7.19.0's dart-dio client inserts path parameter values with
`value.toString()` directly into the route template. Dio later parses that
already-composed path, so reserved characters such as `/` remain structural
path separators. This breaks values that must occupy a single path segment,
for example adlist URLs and Pi-hole config keys such as `dns/hosts`.

Keep this post-processing narrowly scoped to values used while constructing a
`final _path = ...` expression. Query parameters and request bodies are not
changed.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

_RAW_PATH_VALUE = re.compile(
    r"^(?P<indent>\s*)(?P<name>[A-Za-z_][A-Za-z0-9_]*)\.toString\(\),(?P<tail>\s*)$"
)


def encode_file(path: Path) -> int:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    in_path_expression = False
    replacements = 0
    output: list[str] = []

    for line in lines:
        if "final _path =" in line:
            in_path_expression = True

        if in_path_expression:
            newline = "\n" if line.endswith("\n") else ""
            body = line[:-1] if newline else line
            match = _RAW_PATH_VALUE.match(body)
            if match:
                line = (
                    f"{match.group('indent')}Uri.encodeComponent("
                    f"{match.group('name')}.toString()),{match.group('tail')}{newline}"
                )
                replacements += 1

        output.append(line)

        if in_path_expression and line.strip().endswith(";"):
            in_path_expression = False

    if replacements:
        path.write_text("".join(output), encoding="utf-8")

    return replacements


def find_raw_path_values(path: Path) -> list[str]:
    remaining: list[str] = []
    in_path_expression = False

    for line_number, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if "final _path =" in line:
            in_path_expression = True

        if in_path_expression and _RAW_PATH_VALUE.match(line):
            remaining.append(f"{path}:{line_number}: {line.strip()}")

        if in_path_expression and line.strip().endswith(";"):
            in_path_expression = False

    return remaining


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} <generated-api-directory>", file=sys.stderr)
        return 2

    api_dir = Path(sys.argv[1])
    if not api_dir.is_dir():
        print(f"generated API directory does not exist: {api_dir}", file=sys.stderr)
        return 2

    api_files = sorted(api_dir.glob("*_api.dart"))
    if not api_files:
        print(f"no generated *_api.dart files found in {api_dir}", file=sys.stderr)
        return 2

    replacements = sum(encode_file(path) for path in api_files)
    remaining = [item for path in api_files for item in find_raw_path_values(path)]

    if remaining:
        print("raw generated path values remain after encoding pass:", file=sys.stderr)
        print("\n".join(remaining), file=sys.stderr)
        return 1

    print(
        f"Encoded {replacements} generated path parameter occurrence(s) "
        f"across {len(api_files)} API files."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
