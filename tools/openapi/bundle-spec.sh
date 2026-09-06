#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DIR="$SCRIPT_DIR/spec"
TEMP_DIR="$SCRIPT_DIR/.temp-ftl"

# Pin every remote input so generated API changes are reproducible and reviewable.
FTL_REPO="https://github.com/pi-hole/FTL.git"
FTL_REF="fa65a88f8cdef1013594d4de14108077954faea4" # Pi-hole FTL v6.7
SPECS_PATH="src/api/docs/content/specs"
REDOCLY_CLI_VERSION="2.51.2"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "📥 Downloading FTL OpenAPI specs at $FTL_REF (sparse checkout)..."
cleanup
mkdir -p "$TEMP_DIR"

git -C "$TEMP_DIR" init -q
git -C "$TEMP_DIR" remote add origin "$FTL_REPO"
git -C "$TEMP_DIR" sparse-checkout init --cone
git -C "$TEMP_DIR" sparse-checkout set "$SPECS_PATH"
git -C "$TEMP_DIR" fetch --depth 1 --filter=blob:none origin "$FTL_REF"
git -C "$TEMP_DIR" checkout --detach FETCH_HEAD

cd "$SCRIPT_DIR"

echo "📦 Bundling specs with @redocly/cli@$REDOCLY_CLI_VERSION..."
pnpm --package="@redocly/cli@$REDOCLY_CLI_VERSION" dlx redocly bundle "$TEMP_DIR/$SPECS_PATH/main.yaml" -o "$SPEC_DIR/upstream-bundled.yaml"

# Diff check
if [ -f "$SPEC_DIR/bundled.yaml" ]; then
    echo ""
    echo "📊 Diff between current and upstream:"
    diff -u "$SPEC_DIR/bundled.yaml" "$SPEC_DIR/upstream-bundled.yaml" || true
    echo ""
    echo "⚠️  Review the diff above. If acceptable, run:"
    echo "   cp $SPEC_DIR/upstream-bundled.yaml $SPEC_DIR/bundled.yaml"
else
    echo "📝 No existing bundled.yaml. Creating initial version..."
    cp "$SPEC_DIR/upstream-bundled.yaml" "$SPEC_DIR/bundled.yaml"
    echo "✅ Created $SPEC_DIR/bundled.yaml"
fi
