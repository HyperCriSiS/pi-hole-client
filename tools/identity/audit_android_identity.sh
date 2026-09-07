#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="${ANDROID_IDENTITY_CONFIG:-$SCRIPT_DIR/android-identity.env}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "::error::Android identity config not found: $CONFIG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

EXPECTED_APPLICATION_ID="${EXPECTED_APPLICATION_ID:-${ANDROID_APPLICATION_ID:-}}"
EXPECTED_APP_LABEL="${EXPECTED_APP_LABEL:-${ANDROID_APP_LABEL:-}}"
EXPECTED_RESOURCE_APP_NAME="${EXPECTED_RESOURCE_APP_NAME:-${ANDROID_RESOURCE_APP_NAME:-}}"
FORBIDDEN_APPLICATION_IDS="${FORBIDDEN_APPLICATION_IDS:-${ANDROID_FORBIDDEN_APPLICATION_IDS:-}}"

if [[ -z "$EXPECTED_APPLICATION_ID" || -z "$EXPECTED_APP_LABEL" || -z "$EXPECTED_RESOURCE_APP_NAME" ]]; then
  echo "::error::Identity config must define ANDROID_APPLICATION_ID, ANDROID_APP_LABEL, and ANDROID_RESOURCE_APP_NAME."
  exit 1
fi

cd "$REPO_ROOT"

failures=0

fail() {
  echo "::error::$1"
  failures=$((failures + 1))
}

require_file() {
  if [[ ! -f "$1" ]]; then
    fail "Required identity file is missing: $1"
  fi
}

read_gradle_value() {
  local key="$1"
  local file="$2"
  sed -nE "s/^[[:space:]]*${key}[[:space:]]*=?[[:space:]]*['\"]([^'\"]+)['\"].*/\1/p" "$file" | head -n 1
}

BUILD_GRADLE="android/app/build.gradle"
MANIFEST="android/app/src/main/AndroidManifest.xml"
STRINGS="android/app/src/main/res/values/strings.xml"
RELEASE_WORKFLOW=".github/workflows/test-release.yaml"
WIDGET_CONSTANTS="android/app/src/main/kotlin/${EXPECTED_APPLICATION_ID//./\/}/widget/WidgetConstants.kt"

for file in "$BUILD_GRADLE" "$MANIFEST" "$STRINGS" "$RELEASE_WORKFLOW" "$WIDGET_CONSTANTS"; do
  require_file "$file"
done

if (( failures == 0 )); then
  namespace="$(read_gradle_value namespace "$BUILD_GRADLE")"
  application_id="$(read_gradle_value applicationId "$BUILD_GRADLE")"

  [[ "$namespace" == "$EXPECTED_APPLICATION_ID" ]] \
    || fail "Gradle namespace is '$namespace'; expected '$EXPECTED_APPLICATION_ID'."
  [[ "$application_id" == "$EXPECTED_APPLICATION_ID" ]] \
    || fail "Gradle applicationId is '$application_id'; expected '$EXPECTED_APPLICATION_ID'."

  manifest_label="$(
    sed -nE 's/.*android:label="([^"]+)".*/\1/p' "$MANIFEST" | head -n 1
  )"
  [[ "$manifest_label" == "$EXPECTED_APP_LABEL" ]] \
    || fail "Android manifest label is '$manifest_label'; expected '$EXPECTED_APP_LABEL'."

  resource_app_name="$(
    sed -nE 's/.*<string name="app_name">([^<]+)<\/string>.*/\1/p' "$STRINGS" | head -n 1
  )"
  [[ "$resource_app_name" == "$EXPECTED_RESOURCE_APP_NAME" ]] \
    || fail "Android app_name is '$resource_app_name'; expected '$EXPECTED_RESOURCE_APP_NAME'."

  play_package="$(
    sed -nE 's/^[[:space:]]*packageName:[[:space:]]*([^[:space:]#]+).*/\1/p' "$RELEASE_WORKFLOW" | head -n 1
  )"
  [[ "$play_package" == "$EXPECTED_APPLICATION_ID" ]] \
    || fail "Google Play packageName is '$play_package'; expected '$EXPECTED_APPLICATION_ID'."

  mapfile -t widget_actions < <(
    sed -nE 's/.*<action android:name="([^"]+\.widget\.(REFRESH|TOGGLE))".*/\1/p' "$MANIFEST"
  )
  if (( ${#widget_actions[@]} == 0 )); then
    fail "No package-prefixed widget broadcast actions were found in $MANIFEST."
  else
    for action in "${widget_actions[@]}"; do
      [[ "$action" == "$EXPECTED_APPLICATION_ID".widget.* ]] \
        || fail "Widget action '$action' does not use '$EXPECTED_APPLICATION_ID.widget' as its prefix."
    done
  fi

  for action_name in REFRESH TOGGLE; do
    expected_action="$EXPECTED_APPLICATION_ID.widget.$action_name"
    grep -Fq "const val ACTION_${action_name} = \"$expected_action\"" "$WIDGET_CONSTANTS" \
      || fail "WidgetConstants ACTION_${action_name} does not match '$expected_action'."
  done
fi

expected_package_path="${EXPECTED_APPLICATION_ID//./\/}"
for source_set in main debug release test; do
  kotlin_root="android/app/src/$source_set/kotlin"
  [[ -d "$kotlin_root" ]] || continue

  kotlin_count=0
  while IFS= read -r -d '' file; do
    kotlin_count=$((kotlin_count + 1))
    package_name="$(
      sed -nE 's/^[[:space:]]*package[[:space:]]+([^[:space:];]+).*/\1/p' "$file" | head -n 1
    )"

    if [[ -z "$package_name" ]]; then
      fail "Kotlin file has no package declaration: $file"
      continue
    fi

    if [[ "$package_name" != "$EXPECTED_APPLICATION_ID" && "$package_name" != "$EXPECTED_APPLICATION_ID".* ]]; then
      fail "Kotlin package '$package_name' in '$file' is outside '$EXPECTED_APPLICATION_ID'."
      continue
    fi

    relative="${file#"$kotlin_root"/}"
    actual_directory="$(dirname "$relative")"
    expected_directory="${package_name//./\/}"
    [[ "$actual_directory" == "$expected_directory" ]] \
      || fail "Kotlin path/package mismatch: '$file' declares '$package_name'."
  done < <(find "$kotlin_root" -type f -name '*.kt' -print0)

  if (( kotlin_count > 0 )) && [[ ! -d "$kotlin_root/$expected_package_path" ]]; then
    fail "Kotlin source set '$source_set' has no directory for '$EXPECTED_APPLICATION_ID'."
  fi
done

launcher_assets=(
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/mipmap-mdpi/ic_launcher.png
  android/app/src/main/res/mipmap-hdpi/ic_launcher.png
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
  android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
  android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png
  android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png
  android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png
  android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png
  android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png
)
for asset in "${launcher_assets[@]}"; do
  require_file "$asset"
done

if [[ -n "$FORBIDDEN_APPLICATION_IDS" ]]; then
  scan_paths=(android .github/workflows tools/identity/android-identity.env)
  for forbidden_id in $FORBIDDEN_APPLICATION_IDS; do
    [[ -n "$forbidden_id" ]] || continue
    [[ "$forbidden_id" != "$EXPECTED_APPLICATION_ID" ]] \
      || fail "Forbidden application ID '$forbidden_id' is also the expected ID."

    matches="$(
      grep -RFn --binary-files=without-match \
        --exclude='android-identity.env' \
        -- "$forbidden_id" "${scan_paths[@]}" 2>/dev/null || true
    )"
    if [[ -n "$matches" ]]; then
      echo "$matches"
      fail "Forbidden legacy application ID '$forbidden_id' is still present in Android/release wiring."
    fi
  done
fi

if (( failures > 0 )); then
  echo "Android identity audit failed with $failures issue(s)."
  exit 1
fi

echo "Android identity audit passed for $EXPECTED_APPLICATION_ID."
echo "Validated Gradle identity, Kotlin package/path parity, widget manifest/constants actions, display strings, launcher assets, and release packageName."
