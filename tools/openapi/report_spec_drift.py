#!/usr/bin/env python3
"""Report FTL OpenAPI contract drift without regenerating the pinned client."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import yaml

HTTP_METHODS = frozenset({"get", "post", "put", "delete", "patch", "head", "options", "trace"})
ANNOTATIONS = frozenset({"description", "summary", "title", "example", "examples", "externalDocs", "operationId", "tags"})
HOLDS = (
    ("GET", "/info/ftl", "v6.2 integer counter compatibility"),
    ("GET", "/network/gateway", "detailed interfaces/routes missing from generated schema"),
    ("POST", "/action/gravity", "streaming progress contract"),
)


def load_spec(path: Path) -> dict[str, Any]:
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(document, dict) or not isinstance(document.get("paths"), dict):
        raise ValueError(f"Invalid bundled OpenAPI spec (no paths object): {path}")
    if not isinstance(document.get("components", {}), dict):
        raise ValueError(f"Invalid components object: {path}")
    return document


def resolve_pointer(document: dict[str, Any], pointer: str) -> Any:
    if not pointer.startswith("#/"):
        raise ValueError(f"Expected bundled local reference, got {pointer}")
    node: Any = document
    for segment in pointer[2:].split("/"):
        key = segment.replace("~1", "/").replace("~0", "~")
        if not isinstance(node, dict) or key not in node:
            raise ValueError(f"Unresolved OpenAPI reference: {pointer}")
        node = node[key]
    return node


def normalized(value: Any, spec: dict[str, Any], *, expand: bool,
               seen: frozenset[str] = frozenset()) -> Any:
    if isinstance(value, list):
        return [normalized(v, spec, expand=expand, seen=seen) for v in value]
    if isinstance(value, dict):
        result = {}
        for key, item in sorted(value.items()):
            if key in ANNOTATIONS or key.startswith("x-"):
                continue
            if key == "$ref" and expand and isinstance(item, str):
                result[key] = item
                if item not in seen:
                    result["resolved"] = normalized(
                        resolve_pointer(spec, item), spec, expand=True, seen=seen | {item}
                    )
            else:
                result[key] = normalized(item, spec, expand=expand, seen=seen)
        return result
    return value


def fingerprint(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def operation_contracts(spec: dict[str, Any]) -> dict[tuple[str, str], tuple[str, str]]:
    operations = {}
    schemes = spec.get("components", {}).get("securitySchemes", {})
    for path, path_data in spec["paths"].items():
        if not isinstance(path_data, dict):
            raise ValueError(f"Invalid path item: {path}")
        for method, operation in path_data.items():
            if method.lower() not in HTTP_METHODS:
                continue
            if not isinstance(operation, dict):
                raise ValueError(f"Invalid operation: {method} {path}")
            relevant = {
                key: value for key, value in operation.items()
                if key in {"parameters", "requestBody", "responses", "security", "deprecated", "servers", "callbacks"}
            }
            effective_security = operation.get("security", spec.get("security", []))
            used_schemes = {
                name: schemes.get(name)
                for requirement in effective_security
                if isinstance(requirement, dict)
                for name in requirement
            }
            if any(v is None for v in used_schemes.values()):
                raise ValueError(f"Missing security scheme for {method} {path}")
            contract = {
                "operation": relevant,
                "path_parameters": path_data.get("parameters", []),
                "effective_security": effective_security,
                "security_schemes": used_schemes,
            }
            operations[(method.upper(), path)] = (
                fingerprint(normalized(contract, spec, expand=False)),
                fingerprint(normalized(contract, spec, expand=True)),
            )
    return operations


def schema_contracts(spec: dict[str, Any]) -> dict[str, str]:
    schemas = spec.get("components", {}).get("schemas", {})
    if not isinstance(schemas, dict):
        raise ValueError("Invalid components.schemas object")
    return {
        name: fingerprint(normalized(schema, spec, expand=False))
        for name, schema in schemas.items()
    }


def compare(baseline: dict[str, Any], upstream: dict[str, Any], *,
            pinned_revision: str, upstream_revision: str) -> dict[str, Any]:
    before, after = operation_contracts(baseline), operation_contracts(upstream)
    old_schemas, new_schemas = schema_contracts(baseline), schema_contracts(upstream)
    added = sorted(set(after) - set(before))
    removed = sorted(set(before) - set(after))
    changed = sorted(k for k in before.keys() & after.keys() if before[k][1] != after[k][1])
    changes = [
        {"method": method, "path": path,
         "cause": "operation/security" if before[(method, path)][0] != after[(method, path)][0]
         else "referenced schema"}
        for method, path in changed
    ]
    holds = []
    for method, path, reason in HOLDS:
        key = (method, path)
        status = (
            "added" if key not in before and key in after else
            "removed" if key in before and key not in after else
            "changed" if key in before and key in after and before[key][1] != after[key][1] else
            "unchanged" if key in before and key in after else "absent"
        )
        holds.append({"method": method, "path": path, "status": status, "hold_reason": reason})
    schema_added = sorted(new_schemas.keys() - old_schemas.keys())
    schema_removed = sorted(old_schemas.keys() - new_schemas.keys())
    schema_changed = sorted(
        name for name in old_schemas.keys() & new_schemas.keys()
        if old_schemas[name] != new_schemas[name]
    )
    drift = bool(added or removed or changed or schema_added or schema_removed or schema_changed)
    return {
        "pinned_revision": pinned_revision,
        "upstream_revision": upstream_revision,
        "status": "drift" if drift else "unchanged",
        "operations": {
            "added": [{"method": m, "path": p} for m, p in added],
            "removed": [{"method": m, "path": p} for m, p in removed],
            "changed": changes,
        },
        "schemas": {"added": schema_added, "removed": schema_removed, "changed": schema_changed},
        "handwritten_holds": holds,
    }


def markdown_report(report: dict[str, Any]) -> str:
    lines = [
        "# Pi-hole FTL OpenAPI contract drift", "",
        f"Pinned FTL commit: \u0060{report['pinned_revision']}\u0060  ",
        f"Upstream FTL commit: \u0060{report['upstream_revision']}\u0060  ",
        f"Result: **{report['status']}**", "", "## Operations", "",
    ]
    for label in ("added", "removed", "changed"):
        items = report["operations"][label]
        lines.append(f"- {label.capitalize()}: **{len(items)}**")
        for item in items[:20]:
            note = f" ({item['cause']})" if "cause" in item else ""
            lines.append(f"  - \u0060{item['method']} {item['path']}\u0060{note}")
        if len(items) > 20:
            lines.append(f"  - …and {len(items) - 20} more (see JSON artifact)")
    lines += ["", "## Component schemas", ""]
    for label in ("added", "removed", "changed"):
        items = report["schemas"][label]
        lines.append(f"- {label.capitalize()}: **{len(items)}**")
        for name in items[:20]:
            lines.append(f"  - \u0060{name}\u0060")
        if len(items) > 20:
            lines.append(f"  - …and {len(items) - 20} more (see JSON artifact)")
    lines += ["", "## Handwritten v6 compatibility holds", "",
              "| Operation | Status | Hold |", "|---|---|---|"]
    for hold in report["handwritten_holds"]:
        lines.append(
            f"| \u0060{hold['method']} {hold['path']}\u0060 | {hold['status']} | {hold['hold_reason']} |"
        )
    lines += [
        "", "Only contract fields are compared; descriptions/examples are excluded.",
        "A changed schema does **not** prove a handwritten hold is resolved.",
        "Review generated-model parity and behavior before upgrading the pinned spec.", "",
    ]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--upstream", required=True, type=Path)
    parser.add_argument("--pinned-revision", required=True)
    parser.add_argument("--upstream-revision", required=True)
    parser.add_argument("--report-json", required=True, type=Path)
    parser.add_argument("--report-markdown", required=True, type=Path)
    parser.add_argument("--fail-on-drift", action="store_true")
    args = parser.parse_args(argv)
    report = compare(
        load_spec(args.baseline), load_spec(args.upstream),
        pinned_revision=args.pinned_revision, upstream_revision=args.upstream_revision,
    )
    args.report_json.parent.mkdir(parents=True, exist_ok=True)
    args.report_markdown.parent.mkdir(parents=True, exist_ok=True)
    args.report_json.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    args.report_markdown.write_text(markdown_report(report), encoding="utf-8")
    print(f"OpenAPI contract drift: {report['status']} (report: {args.report_markdown})")
    return 2 if args.fail_on_drift and report["status"] == "drift" else 0


if __name__ == "__main__":
    raise SystemExit(main())
