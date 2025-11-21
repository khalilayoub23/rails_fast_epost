#!/usr/bin/env bash
set -euo pipefail

HOST="${DATABASE_HOST:-localhost}"
PORT="${DATABASE_PORT:-5432}"

if command -v pg_isready >/dev/null 2>&1; then
  if pg_isready -h "$HOST" -p "$PORT" -q; then
    exit 0
  fi
else
  echo "pg_isready is not available; skipping PostgreSQL health check." >&2
  exit 0
fi

start_postgres() {
  if command -v service >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    sudo service postgresql start >/dev/null 2>&1 || true
  fi
}

start_postgres

if pg_isready -h "$HOST" -p "$PORT" -q; then
  exit 0
fi

echo "Warning: PostgreSQL is still unreachable at ${HOST}:${PORT}. Please start it manually." >&2
exit 0
