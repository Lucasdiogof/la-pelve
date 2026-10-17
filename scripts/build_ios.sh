#!/usr/bin/env bash
# iOS build for La Pelve. Runs only on a Mac with Xcode (Flutter cannot build iOS on Windows).
# Usage: scripts/build_ios.sh [run|ipa]
#   run  installs a release build on the connected iPhone (default, for QA)
#   ipa  builds an .ipa for TestFlight/App Store (needs signing set up in Xcode)
# Requires env.json in the project root (same file used on Windows, gitignored).
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f env.json ] || { echo "env.json not found in project root (copy it from the other machine)."; exit 1; }
command -v flutter >/dev/null || { echo "flutter not found in PATH."; exit 1; }

flutter pub get
(cd ios && pod install)

case "${1:-run}" in
  run) flutter run --release --dart-define-from-file=env.json ;;
  ipa) flutter build ipa --release --dart-define-from-file=env.json ;;
  *) echo "Unknown mode: $1 (use run or ipa)"; exit 1 ;;
esac
