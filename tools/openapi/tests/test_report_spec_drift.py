import json
import tempfile
import unittest
from pathlib import Path

import yaml

from report_spec_drift import compare, load_spec, main, markdown_report


def spec():
    return {
        "openapi": "3.0.2", "security": [{"sid": []}],
        "components": {
            "securitySchemes": {
                "sid": {"type": "apiKey", "in": "header", "name": "X-FTL-SID"}
            },
            "schemas": {
                "Counter": {"type": "object", "properties": {"total": {"type": "integer"}}},
                "Wrapper": {"type": "object", "properties": {
                    "value": {"$ref": "#/components/schemas/Counter"}
                }},
            },
        },
        "paths": {
            "/info/ftl": {"get": {"description": "old words", "responses": {
                "200": {"description": "okay", "content": {"application/json": {
                    "schema": {"$ref": "#/components/schemas/Wrapper"}
                }}}
            }}},
            "/network/gateway": {"get": {"responses": {"200": {"description": "okay"}}}},
            "/action/gravity": {"post": {"responses": {"200": {"description": "okay"}}}},
        },
    }


class SpecDriftTests(unittest.TestCase):
    def compare_specs(self, before, after):
        return compare(before, after, pinned_revision="pinned", upstream_revision="upstream")

    def test_description_and_key_order_are_not_drift(self):
        before, after = spec(), spec()
        after["paths"]["/info/ftl"]["get"]["description"] = "New documentation"
        after["paths"]["/info/ftl"]["get"]["responses"]["200"]["description"] = "Documented"
        after["components"]["schemas"]["Counter"]["title"] = "Counter"
        self.assertEqual(self.compare_specs(before, after)["status"], "unchanged")

    def test_transitive_nested_schema_change_affects_hold(self):
        before, after = spec(), spec()
        after["components"]["schemas"]["Counter"]["properties"]["total"]["type"] = "string"
        result = self.compare_specs(before, after)
        self.assertEqual(result["operations"]["changed"], [
            {"method": "GET", "path": "/info/ftl", "cause": "referenced schema"}])
        self.assertEqual(result["schemas"]["changed"], ["Counter"])
        self.assertEqual(result["handwritten_holds"][0]["status"], "changed")

    def test_added_removed_operations_and_hold(self):
        before, after = spec(), spec()
        after["paths"].pop("/action/gravity")
        after["paths"]["/extra"] = {"put": {"responses": {"204": {"description": "done"}}}}
        result = self.compare_specs(before, after)
        self.assertEqual(result["operations"]["added"], [{"method": "PUT", "path": "/extra"}])
        self.assertEqual(result["operations"]["removed"], [
            {"method": "POST", "path": "/action/gravity"}])
        self.assertEqual(result["handwritten_holds"][2]["status"], "removed")

    def test_security_changes_are_contract_drift(self):
        before, after = spec(), spec()
        after["components"]["securitySchemes"]["sid"]["name"] = "X-New-Token"
        result = self.compare_specs(before, after)
        self.assertEqual(len(result["operations"]["changed"]), 3)
        self.assertTrue(all(x["cause"] == "operation/security"
                            for x in result["operations"]["changed"]))

    def test_invalid_reference_fails_closed(self):
        before = spec()
        before["components"]["schemas"].pop("Counter")
        with self.assertRaisesRegex(ValueError, "Unresolved OpenAPI reference"):
            self.compare_specs(before, spec())

    def test_cli_writes_reports_and_optional_drift_exit(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            before, after = spec(), spec()
            after["paths"]["/network/gateway"]["get"]["responses"]["201"] = {
                "description": "created"}
            for name, value in [("before.yaml", before), ("after.yaml", after)]:
                (root / name).write_text(yaml.safe_dump(value), encoding="utf-8")
            args = [
                "--baseline", str(root / "before.yaml"),
                "--upstream", str(root / "after.yaml"),
                "--pinned-revision", "a" * 40,
                "--upstream-revision", "b" * 40,
                "--report-json", str(root / "out.json"),
                "--report-markdown", str(root / "out.md"),
            ]
            self.assertEqual(main(args + ["--fail-on-drift"]), 2)
            document = json.loads((root / "out.json").read_text())
            self.assertEqual(document["status"], "drift")
            self.assertIn("GET /network/gateway", (root / "out.md").read_text())
            self.assertEqual(main(args), 0)
            self.assertEqual(load_spec(root / "before.yaml")["openapi"], "3.0.2")
            self.assertIn("Handwritten", markdown_report(document))


if __name__ == "__main__":
    unittest.main()
