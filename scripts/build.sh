#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
DOWNLOAD_DIR="$BUILD_DIR/downloads"
WORK_DIR="$BUILD_DIR/work"
APP_NAME="BaseX"
DEFAULT_BASEX_VERSION_FILE="$ROOT_DIR/.basex-version"
DEFAULT_BASEX_VERSION="$(tr -d '[:space:]' < "$DEFAULT_BASEX_VERSION_FILE" 2>/dev/null || true)"
BASEX_VERSION="${BASEX_VERSION:-${DEFAULT_BASEX_VERSION:-12.2}}"
BASEX_VERSION_TAG="${BASEX_VERSION//./}"
BASEX_ZIP_URL="${BASEX_ZIP_URL:-https://files.basex.org/releases/${BASEX_VERSION}/BaseX${BASEX_VERSION_TAG}.zip}"
CREATE_DMG="${CREATE_DMG:-0}"
ZIP_PATH="$DOWNLOAD_DIR/BaseX${BASEX_VERSION_TAG}.zip"
UPSTREAM_DIR="$WORK_DIR/upstream"
STAGE_DIR="$WORK_DIR/stage"
APP_DIR="$DIST_DIR/${APP_NAME}.app"
DMG_PATH="$DIST_DIR/${APP_NAME}-${BASEX_VERSION}.dmg"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

detect_java_home() {
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then
    echo "$JAVA_HOME"
    return
  fi

  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    local detected
    detected="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
    if [[ -n "$detected" && -x "$detected/bin/java" ]]; then
      echo "$detected"
      return
    fi
  fi

  echo "failed to locate JAVA_HOME for JDK 17+" >&2
  exit 1
}

prepare_dirs() {
  rm -rf "$WORK_DIR" "$DIST_DIR"
  mkdir -p "$DOWNLOAD_DIR" "$UPSTREAM_DIR" "$STAGE_DIR" "$DIST_DIR"
}

download_upstream() {
  if [[ -f "$ZIP_PATH" ]]; then
    echo "Using cached upstream archive: $ZIP_PATH"
  else
    echo "Downloading BaseX ${BASEX_VERSION} from ${BASEX_ZIP_URL}"
    curl -L --fail --output "$ZIP_PATH" "$BASEX_ZIP_URL"
  fi
  unzip -q -o "$ZIP_PATH" -d "$UPSTREAM_DIR"
}

detect_upstream_root() {
  local extracted_root
  extracted_root="$(find "$UPSTREAM_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "${extracted_root}" ]]; then
    echo "failed to detect extracted BaseX directory" >&2
    exit 1
  fi
  echo "$extracted_root"
}

stage_upstream() {
  local extracted_root="$1"
  cp -R "$extracted_root"/. "$STAGE_DIR/"
}

create_runtime() {
  local java_home="$1"
  cp -R "$java_home" "$WORK_DIR/runtime"
}

write_launcher() {
  local launcher_path="$APP_DIR/Contents/MacOS/BaseX"
  cat >"$launcher_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JAVA_BIN="$APP_ROOT/runtime/bin/java"
APP_DATA="$APP_ROOT/app"
CLASSPATH="$APP_DATA/BaseX.jar:$APP_DATA/lib/*:$APP_DATA/lib/custom/*"

exec "$JAVA_BIN" \
  -Xdock:name=BaseX \
  -Dapple.laf.useScreenMenuBar=true \
  -Dcom.apple.mrj.application.apple.menu.about.name=BaseX \
  -cp "$CLASSPATH" \
  org.basex.BaseXGUI "$@"
EOF
  chmod +x "$launcher_path"
}

write_info_plist() {
  sed "s/__VERSION__/${BASEX_VERSION}/g" \
    "$ROOT_DIR/resources/Info.plist" >"$APP_DIR/Contents/Info.plist"
}

assemble_app() {
  mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$APP_DIR/Contents/app"
  cp -R "$STAGE_DIR"/. "$APP_DIR/Contents/app/"
  cp -R "$WORK_DIR/runtime" "$APP_DIR/Contents/runtime"
  write_info_plist
  write_launcher
}

create_dmg() {
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$APP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null
}

validate_inputs() {
  if [[ -z "$BASEX_VERSION" ]]; then
    echo "BASEX_VERSION must not be empty" >&2
    exit 1
  fi
}

main() {
  require_cmd curl
  require_cmd unzip
  require_cmd java
  require_cmd hdiutil
  validate_inputs

  prepare_dirs
  download_upstream

  local java_home
  java_home="$(detect_java_home)"

  local extracted_root
  extracted_root="$(detect_upstream_root)"
  stage_upstream "$extracted_root"
  create_runtime "$java_home"
  assemble_app
  if [[ "$CREATE_DMG" == "1" ]]; then
    create_dmg
  else
    echo "Skipping dmg creation. Set CREATE_DMG=1 to build a dmg."
  fi

  echo "Built:"
  echo "  $APP_DIR"
  if [[ "$CREATE_DMG" == "1" ]]; then
    echo "  $DMG_PATH"
  fi
}

main "$@"
