#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DIR="$SCRIPT_DIR/spec"
TEMP_DIR="$SCRIPT_DIR/.temp-ftl"
VERSIONS_FILE="$SCRIPT_DIR/versions.env"

# shellcheck disable=SC1090
source "$VERSIONS_FILE"

SPECS_PATH="src/api/docs/content/specs"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "📥 Downloading pinned FTL OpenAPI specs..."
rm -rf "$TEMP_DIR"
git init -q "$TEMP_DIR"
git -C "$TEMP_DIR" remote add origin "$FTL_REPO"
git -C "$TEMP_DIR" sparse-checkout init --cone
git -C "$TEMP_DIR" sparse-checkout set "$SPECS_PATH"
git -C "$TEMP_DIR" fetch --depth 1 origin "$FTL_COMMIT"
git -C "$TEMP_DIR" checkout -q --detach FETCH_HEAD

ACTUAL_FTL_COMMIT="$(git -C "$TEMP_DIR" rev-parse HEAD)"
if [ "$ACTUAL_FTL_COMMIT" != "$FTL_COMMIT" ]; then
    echo "❌ Expected FTL commit $FTL_COMMIT but checked out $ACTUAL_FTL_COMMIT" >&2
    exit 1
fi

echo "📦 Bundling specs with @redocly/cli@$REDOCLY_CLI_VERSION..."
pnpm --package="@redocly/cli@$REDOCLY_CLI_VERSION" dlx redocly bundle \
    "$TEMP_DIR/$SPECS_PATH/main.yaml" \
    -o "$SPEC_DIR/upstream-bundled.yaml"

if [ -f "$SPEC_DIR/bundled.yaml" ]; then
    echo ""
    echo "📊 Diff between current and pinned upstream:"
    diff -u "$SPEC_DIR/bundled.yaml" "$SPEC_DIR/upstream-bundled.yaml" || true
    echo ""
    echo "⚠️  Review the diff above. If acceptable, run:"
    echo "   cp $SPEC_DIR/upstream-bundled.yaml $SPEC_DIR/bundled.yaml"
else
    echo "📝 No existing bundled.yaml. Creating initial version..."
    cp "$SPEC_DIR/upstream-bundled.yaml" "$SPEC_DIR/bundled.yaml"
    echo "✅ Created $SPEC_DIR/bundled.yaml"
fi
