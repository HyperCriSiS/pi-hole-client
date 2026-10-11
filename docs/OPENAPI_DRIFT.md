# Pi-hole FTL OpenAPI contract drift report

The workflow `FTL OpenAPI contract drift` runs every Monday at **05:13 UTC** and supports **Actions → Run workflow** for manual checks. It compares the checked-in `tools/openapi/spec/bundled.yaml` (pinned FTL v6.7) with the latest `pi-hole/FTL` `master` source, bundled with the **same pinned Redocly version** in `tools/openapi/versions.env`.

## Output and expected status

- A Markdown summary in the Actions job summary, plus an artifact named `ftl-openapi-contract-drift` containing Markdown and full JSON, retained for 30 days.
- Added/removed/changed HTTP operations, schema changes, and explicit states for the three handwritten holds: `GET /info/ftl`, `GET /network/gateway`, `POST /action/gravity`.
- A scheduled/manual check **fails on actual contract drift** to surface it in Actions. This is a review signal, not an application test failure. Descriptions, examples and other documentation-only fields do not count.
- Network/bundling failures also fail the job; distinguish these from a generated `status: drift` report before drawing conclusions.

The checker expands nested local OpenAPI references, including schemas referenced through other schemas. However, an unchanged OpenAPI specification **cannot prove runtime behavior or compatibility**. In particular, a changed endpoint/schema does not automatically resolve the documented v6.2 FTL counter, detailed gateway, or gravity streaming holds. Review source behavior, generated model parity and existing regression coverage first.

The workflow uses a shallow sparse checkout of upstream documentation, read-only repository permissions, Python 3.12 with pinned `PyYAML==6.0.3`, pinned Redocly and pinned pnpm. It never modifies `versions.env`, the bundled baseline, generated Dart code, authentication, or release artifacts. It does not create Issues (Issues are disabled in this fork).

## Local, offline comparison

With two already bundled YAML files:

```bash
python3 -m pip install PyYAML==6.0.3
python3 tools/openapi/report_spec_drift.py \
  --baseline tools/openapi/spec/bundled.yaml \
  --upstream /path/to/newly-bundled-upstream.yaml \
  --pinned-revision fa65a88f8cdef1013594d4de14108077954faea4 \
  --upstream-revision VERIFIED_UPSTREAM_COMMIT \
  --report-json /tmp/ftl-drift.json \
  --report-markdown /tmp/ftl-drift.md \
  --fail-on-drift
```

The comparison writes reports even when returning exit status 2 for detected drift. Without `--fail-on-drift`, a detected change still produces the reports and exits 0. Invalid specifications or unresolved bundled references fail with a nonzero exit status rather than silently producing a misleading no-change result.

Run isolated regression checks using:

```bash
python3 -m unittest discover -s tools/openapi/tests -p 'test_*.py' -v
```

The separate PR job runs these tests and compares the pinned YAML file against itself, without fetching upstream. A full comparison requires remote upstream availability and therefore runs only on the weekly schedule or manual dispatch.
