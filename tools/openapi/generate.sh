#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
VERSIONS_FILE="$SCRIPT_DIR/versions.env"

# shellcheck disable=SC1090
source "$VERSIONS_FILE"

# Run from project root so relative paths in config work
cd "$PROJECT_ROOT"

GENERATED_PKG="$PROJECT_ROOT/lib/data/services/api/generated/v6"

if ! grep -Eq "\"version\"[[:space:]]*:[[:space:]]*\"$OPENAPI_GENERATOR_VERSION\"" "$PROJECT_ROOT/openapitools.json"; then
    echo "❌ Root openapitools.json is not pinned to OpenAPI Generator $OPENAPI_GENERATOR_VERSION" >&2
    exit 1
fi

if ! grep -Eq "\"version\"[[:space:]]*:[[:space:]]*\"$OPENAPI_GENERATOR_VERSION\"" "$SCRIPT_DIR/openapitools.json"; then
    echo "❌ tools/openapi/openapitools.json is not pinned to OpenAPI Generator $OPENAPI_GENERATOR_VERSION" >&2
    exit 1
fi

echo "🔧 Generating v6 API client with wrapper $OPENAPI_GENERATOR_WRAPPER_VERSION and generator $OPENAPI_GENERATOR_VERSION..."
pnpm dlx "@openapitools/openapi-generator-cli@$OPENAPI_GENERATOR_WRAPPER_VERSION" generate \
    -c "$SCRIPT_DIR/openapi-generator-config.yaml"

echo "🔧 Fixing generated pubspec.yaml..."
sed -i "s/sdk: '>=3.5.0 <4.0.0'/sdk: '>=3.8.0 <4.0.0'/" "$GENERATED_PKG/pubspec.yaml"
sed -i "s/build_runner: any/build_runner: ^2.7.1/" "$GENERATED_PKG/pubspec.yaml"
sed -i "s/json_serializable: '\^6.9.3'/json_serializable: '^6.11.0'/" "$GENERATED_PKG/pubspec.yaml"

# OpenAPI Generator creates an empty placeholder StringOrList class in model/
# We overwrite it with our working implementation from templates/
echo "🔧 Copying StringOrList class..."
cp "$SCRIPT_DIR/templates/string_or_list.dart" "$GENERATED_PKG/lib/src/model/string_or_list.dart"

# OpenAPI Generator creates `this.field = [0]` which should be `this.field = const [0]`
echo "🔧 Fixing non-const default values..."
find "$GENERATED_PKG/lib" -name "*.dart" -exec sed -i 's/= \(\[[^]]*\]\),$/= const \1,/' {} \;

echo "🧹 Removing unnecessary generated directories..."
rm -rf "$GENERATED_PKG/test"
rm -rf "$GENERATED_PKG/doc"
# rm -rf "$GENERATED_PKG/.openapi-generator"
# rm -f "$GENERATED_PKG/README.md"

echo "🏗️ Running build_runner in generated package..."
cd "$GENERATED_PKG"
rm -rf .dart_tool build
dart pub get
dart run build_runner build --delete-conflicting-outputs

echo "🏗️ Running build_runner in project root..."
cd "$PROJECT_ROOT"
dart run build_runner build --delete-conflicting-outputs

echo "✅ Generation complete!"
