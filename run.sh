#!/usr/bin/env bash
# Starts the whole demo: Postgres (Docker), the API (port 3001) and the web app (port 3000).
# Usage: ./run.sh            start everything (installs and builds on first run)
#        ./run.sh --rebuild  rebuild the web app first (after code changes)
# Stop with Ctrl+C.

set -euo pipefail
cd "$(dirname "$0")"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

command -v docker >/dev/null || fail "Docker is not installed."
command -v node >/dev/null || fail "Node.js is not installed (18 or newer)."
docker info >/dev/null 2>&1 || fail "Docker is not running. Start Docker Desktop and try again."

for port in 3000 3001; do
  if lsof -ti ":$port" >/dev/null 2>&1; then
    fail "Port $port is already in use. Stop whatever is using it: lsof -ti :$port | xargs kill"
  fi
done

say "Starting the database"
docker compose up -d --wait

[ -f .env ] || { cp .env.example .env; say "Created .env (no API key yet, so the demo runs offline)"; }

if [ ! -d node_modules ]; then say "Installing API dependencies"; npm install --silent; fi
if [ ! -d web/node_modules ]; then say "Installing web dependencies"; npm --prefix web install --silent; fi
if [ ! -f web/.next/BUILD_ID ] || [ "${1:-}" = "--rebuild" ]; then
  say "Building the web app"
  npm --prefix web run build >/dev/null
fi

cleanup() {
  trap - INT TERM EXIT
  say "Stopping"
  kill "$API_PID" "$WEB_PID" 2>/dev/null || true
  wait 2>/dev/null || true
}
trap cleanup INT TERM EXIT

say "Starting the API"
node server.js &
API_PID=$!

say "Starting the web app"
npm --prefix web run start -- -p 3000 >/dev/null &
WEB_PID=$!

# Wait until the app answers, then open the browser.
for _ in $(seq 1 60); do
  if curl -sf http://localhost:3000/api/state >/dev/null 2>&1; then break; fi
  kill -0 "$API_PID" 2>/dev/null || fail "The API stopped. See the messages above."
  sleep 0.5
done
say "Ready at http://localhost:3000   (Ctrl+C to stop)"
command -v open >/dev/null && open http://localhost:3000

wait -n "$API_PID" "$WEB_PID" 2>/dev/null || wait
