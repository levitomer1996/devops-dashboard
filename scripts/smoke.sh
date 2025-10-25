#!/usr/bin/env bash
set -euo pipefail
for url in http://localhost:3001/health http://localhost:3002/health; do
  echo "Checking $url"
  curl -fsSL "$url" | jq . || echo "Non-JSON health"
done
