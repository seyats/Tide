#!/usr/bin/env bash
set -euo pipefail

source Tools/run-xcodebuild-with-logs.sh

mkdir -p build

REPORT_PATH="build/DerivedData"
if ! run_and_capture xcodebuild \
  -project Tide.xcodeproj \
  -scheme Tide \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/TideBuild.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  build; then
  finish_with_report 1 "Simulator build failed. Check ${LOG_FILE} for the exact compiler error."
fi

SIMULATOR_ID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/{print $2; exit}')"
if [[ -z "${SIMULATOR_ID}" ]]; then
  finish_with_report 1 "No available iPhone simulator found."
fi

xcrun simctl boot "${SIMULATOR_ID}" 2>/dev/null || true

REPORT_PATH="build/TideTests.xcresult"
if ! run_and_capture xcodebuild \
  -project Tide.xcodeproj \
  -scheme Tide \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=${SIMULATOR_ID}" \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/TideTests.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  test; then
  finish_with_report 1 "Tests failed. Check ${LOG_FILE} for the exact test or compiler error."
fi
