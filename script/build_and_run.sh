#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="QuickMD"
BUNDLE_ID="dev.bunn.quickmd"
EXTENSION_PROCESS_NAME="Markdown Preview"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/QuickMD.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.derivedData"
BUILT_APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/QuickMD.app"
BUILT_EXTENSION="$BUILT_APP_BUNDLE/Contents/PlugIns/Markdown Preview.appex"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/QuickMD.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/QuickMD"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
pkill -x "$EXTENSION_PROCESS_NAME" >/dev/null 2>&1 || true

cd "$ROOT_DIR"
xcodegen generate
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme QuickMD \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  build

mkdir -p "$DIST_DIR"
/usr/bin/ditto "$BUILT_APP_BUNDLE" "$APP_BUNDLE"
pluginkit -r "$BUILT_EXTENSION" >/dev/null 2>&1 || true

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
