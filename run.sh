#!/usr/bin/env bash
# Starts the whole demo: Postgres (Docker), the API and the web app.
# Asks for the web and API ports (Enter keeps the defaults, 3000 and 3001).
# Usage: ./run.sh            start everything (installs and builds on first run)
#        ./run.sh --rebuild  rebuild the web app first (after code changes)
# Without a terminal (or to skip the questions) set WEB_PORT and API_PORT instead.
# Stop with Ctrl+C.

set -euo pipefail
cd "$(dirname "$0")"

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

command -v docker >/dev/null || fail "Docker is not installed."
command -v node >/dev/null || fail "Node.js is not installed (18 or newer)."
docker info >/dev/null 2>&1 || fail "Docker is not running. Start Docker Desktop and try again."

port_in_use() { lsof -ti ":$1" -sTCP:LISTEN >/dev/null 2>&1; }

# ask_port <label> <default> <port to avoid>: prompts until it gets a free, valid port.
ask_port() {
  local label=$1 default=$2 avoid=${3:-} port
  while true; do
    read -r -p "$label port [$default]: " port </dev/tty || { echo >&2; fail "No $label port given."; }
    port=${port:-$default}
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
      echo "  Enter a number from 1 to 65535." >&2
    elif [ "$port" = "$avoid" ]; then
      echo "  The web app and the API need different ports." >&2
    elif port_in_use "$port"; then
      echo "  Port $port is already in use (lsof -ti :$port shows what uses it). Pick another one." >&2
    else
      echo "$port"
      return
    fi
  done
}

if [ -z "${WEB_PORT:-}${API_PORT:-}" ] && [ -t 0 ]; then
  WEB_PORT=$(ask_port "Web app" 3000) || exit 1
  API_PORT=$(ask_port "API" 3001 "$WEB_PORT") || exit 1
else
  WEB_PORT=${WEB_PORT:-3000}
  API_PORT=${API_PORT:-3001}
  [ "$WEB_PORT" != "$API_PORT" ] || fail "WEB_PORT and API_PORT must differ."
  for port in "$WEB_PORT" "$API_PORT"; do
    port_in_use "$port" && fail "Port $port is already in use. Stop whatever is using it: lsof -ti :$port | xargs kill"
  done
fi
export API_PORT WEB_PORT
# Next.js bakes the /api proxy target into the build, so a new API port needs a rebuild.
export API_URL="http://localhost:$API_PORT"

say "Starting the database"
docker compose up -d --wait

[ -f .env ] || { cp .env.example .env; say "Created .env (no API key yet, so the demo runs offline)"; }

if [ ! -d node_modules ]; then say "Installing API dependencies"; npm install --silent; fi
if [ ! -d web/node_modules ]; then say "Installing web dependencies"; npm --prefix web install --silent; fi
BUILT_FOR=web/.next/api-url
if [ ! -f web/.next/BUILD_ID ] || [ "${1:-}" = "--rebuild" ] || [ "$(cat "$BUILT_FOR" 2>/dev/null)" != "$API_URL" ]; then
  say "Building the web app"
  npm --prefix web run build >/dev/null
  echo "$API_URL" >"$BUILT_FOR"
fi

cleanup() {
  trap - INT TERM EXIT
  say "Stopping"
  kill "$API_PID" "$WEB_PID" 2>/dev/null || true
  wait 2>/dev/null || true
}
trap cleanup INT TERM EXIT

say "Starting the API on port $API_PORT"
node server.js &
API_PID=$!

say "Starting the web app on port $WEB_PORT"
npm --prefix web run start -- -p "$WEB_PORT" >/dev/null &
WEB_PID=$!

# Wait until the app answers, then open the browser.
for _ in $(seq 1 60); do
  if curl -sf http://localhost:$WEB_PORT/api/state >/dev/null 2>&1; then break; fi
  kill -0 "$API_PID" 2>/dev/null || fail "The API stopped. See the messages above."
  sleep 0.5
done
say "Ready at http://localhost:$WEB_PORT   (Ctrl+C to stop)"
command -v open >/dev/null && open "http://localhost:$WEB_PORT"

wait -n "$API_PID" "$WEB_PID" 2>/dev/null || wait
