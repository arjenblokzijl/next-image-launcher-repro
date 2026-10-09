#!/usr/bin/env bash
set -euo pipefail
BASE="${1:?deployment url}"

curl -s -o /dev/null -w "%{http_code}\n" "${BASE}/_next/image?url=%2Fapi%2Fimage&w=64&q=75"
