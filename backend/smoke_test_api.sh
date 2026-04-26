#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-}"
if [[ -z "${BASE_URL}" ]]; then
  echo "Usage: bash backend/smoke_test_api.sh <base_url>"
  echo "Example: bash backend/smoke_test_api.sh https://jldwa4t8ph.execute-api.us-east-1.amazonaws.com"
  exit 1
fi

check_get() {
  local path="$1"
  local code
  code="$(curl -s -o /tmp/carecoord_get.out -w "%{http_code}" "${BASE_URL}${path}")"
  echo "GET ${path} -> ${code}"
  python3 - <<'PY'
from pathlib import Path
body = Path("/tmp/carecoord_get.out").read_text().strip()
print((body[:220] + "...") if len(body) > 220 else body)
PY
}

check_post_trigger() {
  local payload='{"agent":"scheduling","payload":{"patient_id":"demo-patient-1","patient_name":"Demo Patient","test_type":"Complete Blood Count (CBC)","priority":"high"}}'
  local code
  code="$(curl -s -o /tmp/carecoord_post.out -w "%{http_code}" \
    -X POST "${BASE_URL}/agents/trigger" \
    -H "Content-Type: application/json" \
    -d "${payload}")"
  echo "POST /agents/trigger -> ${code}"
  python3 - <<'PY'
from pathlib import Path
body = Path("/tmp/carecoord_post.out").read_text().strip()
print((body[:220] + "...") if len(body) > 220 else body)
PY
}

echo "Testing base URL: ${BASE_URL}"
echo

check_get "/patients"
echo
check_get "/beds"
echo
check_get "/lab-results"
echo
check_get "/agent-events"
echo
check_post_trigger
