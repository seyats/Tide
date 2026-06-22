#!/usr/bin/env bash
set -euo pipefail

source Tools/run-xcodebuild-with-logs.sh

MARKETING_VERSION="${MARKETING_VERSION:-1.0.0}"
CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION:-1}"

rm -rf build/archive build/export build/unsigned
mkdir -p build/archive build/export build/unsigned/Payload

xcodegen generate

REPORT_PATH="build/DerivedData"
if ! run_and_capture xcodebuild \
  -project Tide.xcodeproj \
  -scheme Tide \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/archive/Tide.xcarchive \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}" \
  PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-com.tide.app}" \
  MARKETING_VERSION="${MARKETING_VERSION}" \
  CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  archive; then
  finish_with_report 1 "xcodebuild failed. Check ${LOG_FILE} for the exact compiler error."
fi

APP_PATH="$(find build/archive/Tide.xcarchive/Products/Applications -maxdepth 1 -name '*.app' -print -quit)"
if [[ -z "${APP_PATH}" ]]; then
  REPORT_PATH="build/archive"
  finish_with_report 1 "Unsigned archive completed but Tide.app was not found."
fi

cp -R "${APP_PATH}" build/unsigned/Payload/
cd build/unsigned
zip -qry ../export/Tide-unsigned.ipa Payload

REPORT_PATH="build"
zip -qj "../artifacts/build-report-${STAMP}.zip" "../logs/$(basename "${LOG_FILE}")" 2>/dev/null || true
