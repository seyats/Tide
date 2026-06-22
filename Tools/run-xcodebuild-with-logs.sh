#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-build/logs}"
ARTIFACT_DIR="${ARTIFACT_DIR:-build/artifacts}"
mkdir -p "${LOG_DIR}" "${ARTIFACT_DIR}"

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/xcodebuild-${STAMP}.log"
ZIP_FILE="${ARTIFACT_DIR}/build-report-${STAMP}.zip"

run_and_capture() {
  local status=0
  set +e
  "$@" 2>&1 | tee "${LOG_FILE}"
  status=${PIPESTATUS[0]}
  set -e
  return "${status}"
}

finish_with_report() {
  local exit_code="$1"
  local message="$2"
  echo "${message}"
  if command -v zip >/dev/null 2>&1; then
    zip -q -j "${ZIP_FILE}" "${LOG_FILE}" 2>/dev/null || true
    if [[ -n "${REPORT_PATH:-}" && -e "${REPORT_PATH}" ]]; then
      zip -q -r "${ZIP_FILE}" "${REPORT_PATH}" 2>/dev/null || true
    fi
    echo "Build report: ${ZIP_FILE}"
  fi
  exit "${exit_code}"
}

