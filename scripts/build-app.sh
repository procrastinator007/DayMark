#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Daymark.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"

cd "$ROOT"
if [ -d /Applications/Xcode.app/Contents/Developer ]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  export SDKROOT="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
  SWIFT="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"
else
  SWIFT="$(command -v swift)"
fi
export CLANG_MODULE_CACHE_PATH="$ROOT/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT/.build/ModuleCache"
"$SWIFT" build -c release
rm -rf "$APP"
mkdir -p "$MACOS"
cp ".build/release/Daymark" "$MACOS/Daymark"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
chmod +x "$MACOS/Daymark"
codesign --force --sign - "$APP"

echo "Built $APP"
