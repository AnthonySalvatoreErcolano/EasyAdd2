#!/bin/bash
# Captures App Store screenshots from a simulator using the debug-only demo
# mode in lib/demo.dart. Build a Debug simulator app first, then run:
#   tool/capture_screenshots.sh <simulator-udid> <out-dir> <path/to/Runner.app>
set -euo pipefail
DEV=$1; OUT=$2; APP=$3; BUNDLE=com.anthonyercolano.constructioncalculator
mkdir -p "$OUT"
xcrun simctl boot "$DEV" 2>/dev/null || true
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl status_bar "$DEV" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --dataNetwork wifi
xcrun simctl ui "$DEV" appearance dark || true
xcrun simctl install "$DEV" "$APP"
TMP="$(xcrun simctl get_app_container "$DEV" "$BUNDLE" data)/tmp"
mkdir -p "$TMP"
n=0
for scene in calculator live-answer concrete stairs board-feet history; do
  n=$((n+1))
  xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
  printf '%s' "$scene" > "$TMP/easyadd_demo_scene"
  xcrun simctl launch "$DEV" "$BUNDLE" >/dev/null
  # Debug builds start slowly; give the app and the scene time to settle.
  sleep 9
  xcrun simctl io "$DEV" screenshot "$OUT/0$n-$scene.png" >/dev/null 2>&1
  echo "captured $OUT/0$n-$scene.png"
done
xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
rm -f "$TMP/easyadd_demo_scene"
xcrun simctl status_bar "$DEV" clear
