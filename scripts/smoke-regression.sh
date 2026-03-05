#!/usr/bin/env bash
set -euo pipefail

PROJECT="Murmur.xcodeproj"
SCHEME="Murmur"
CONFIG="Debug"
SDK="macosx"
DESTINATION="platform=macOS"

xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" -sdk "$SDK" build
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" -sdk "$SDK" test -destination "$DESTINATION"
