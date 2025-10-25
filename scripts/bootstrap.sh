#!/usr/bin/env bash
set -euo pipefail
echo "Bootstrapping local dev..."
(cd services/users-service && npm ci && npm run build && npm run start:prod) &
(cd services/tasks-service && npm ci && npm run build && npm run start:prod) &
wait
