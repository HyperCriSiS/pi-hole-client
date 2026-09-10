#!/usr/bin/env python3
"""Fail when production v6 code expands the handwritten client boundary."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
V6_REPOSITORIES = ROOT / "lib/data/repositories/api/v6"
FACTORY = ROOT / "lib/data/repositories/api/repository_factory.dart"
LEGACY_IMPORT = (
    "import 'package:pi_hole_client/data/services/api/"
    "pihole_v6_api_client.dart';"
)

# Three production repositories remain on the handwritten transport for
# documented behavior/schema holds. Session cache/store keep a nullable client
# only as a compatibility seam for existing tests; production binds `service`.
ALLOWED_V6_IMPORTS = {
    "actions_respository.dart",
    "ftl_repository.dart",
    "network_repository.dart",
    "v6_session_cache.dart",
    "v6_session_cache_store.dart",
}
PRODUCTION_HOLDS = {
    "ActionsRepositoryV6",
    "FtlRepositoryV6",
    "NetworkRepositoryV6",
}


def fail(message: str) -> None:
    raise SystemExit(f"legacy-v6-boundary: {message}")


def main() -> None:
    importers = {
        path.name
        for path in V6_REPOSITORIES.glob("*.dart")
        if LEGACY_IMPORT in path.read_text()
    }
    if importers != ALLOWED_V6_IMPORTS:
        added = sorted(importers - ALLOWED_V6_IMPORTS)
        missing = sorted(ALLOWED_V6_IMPORTS - importers)
        fail(f"unexpected import boundary; added={added}, missing={missing}")

    factory = FACTORY.read_text()
    if factory.count(LEGACY_IMPORT) != 1:
        fail("repository factory must import the handwritten v6 client once")
    if factory.count("final client = PiholeV6ApiClient(") != 1:
        fail("repository factory must create exactly one handwritten v6 client")

    try:
        v6_section = factory.split("case SupportedApiVersions.v6:", 1)[1].split(
            "default:", 1
        )[0]
    except IndexError as exc:
        raise SystemExit("legacy-v6-boundary: could not isolate v6 factory section") from exc

    injected = set(
        re.findall(
            r"\b([A-Za-z0-9_]+RepositoryV6)\(\s*\n\s*client: client,",
            v6_section,
        )
    )
    if injected != PRODUCTION_HOLDS:
        fail(
            "handwritten client must only be injected into documented holds; "
            f"found={sorted(injected)}"
        )
    if v6_section.count("client: client,") != len(PRODUCTION_HOLDS):
        fail("v6 factory contains an unrecognized handwritten client injection")

    # Production session management must remain generated-service-only even
    # while its nullable handwritten-client seam exists for compatibility tests.
    for constructor in ("sessionCacheStore?.getOrCreate(", "V6SessionCache("):
        start = v6_section.find(constructor)
        if start < 0:
            fail(f"missing production session-cache construction: {constructor}")
        block = v6_section[start : start + 320]
        if "service: generatedService" not in block:
            fail(f"{constructor} must bind generatedService in production")
        if "client: client" in block:
            fail(f"{constructor} must not bind the handwritten client in production")

    cache = (V6_REPOSITORIES / "v6_session_cache.dart").read_text()
    store = (V6_REPOSITORIES / "v6_session_cache_store.dart").read_text()
    if "PiholeV6ApiClient? client" not in cache:
        fail("session cache compatibility seam changed; re-audit its production boundary")
    if "PiholeV6ApiClient? client" not in store:
        fail("session cache store compatibility seam changed; re-audit its boundary")

    print("Legacy v6 boundary audit passed.")
    print("Production handwritten holds: ActionsRepositoryV6, FtlRepositoryV6, NetworkRepositoryV6.")
    print("V6SessionCache/V6SessionCacheStore legacy client remains test-only in production wiring.")


if __name__ == "__main__":
    main()
