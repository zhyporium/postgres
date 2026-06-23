#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CTX="${ROOT}/docker/18"
PASS="${POSTGRES_PASSWORD:-secret}"

NAMES=(postgres postgres-pgvector postgres-timescale postgres-pgvector-timescale)
DOCKERFILES=(docker/18/Dockerfile docker/18/pgvector/Dockerfile docker/18/timescale/Dockerfile docker/18/pgvector-timescale/Dockerfile)
EXPECTED_LIST=(
  "pg_stat_statements pg_trgm unaccent"
  "pg_stat_statements pg_trgm unaccent vector"
  "pg_stat_statements pg_trgm unaccent timescaledb"
  "pg_stat_statements pg_trgm unaccent vector timescaledb"
)

cleanup() {
  docker rm -f pg-validate >/dev/null 2>&1 || true
}
trap cleanup EXIT

failed=0

for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  dockerfile="${DOCKERFILES[$i]}"
  expected="${EXPECTED_LIST[$i]}"

  echo "=== BUILD ${name} ==="
  if ! docker build -f "${ROOT}/${dockerfile}" -t "validate/${name}:18" "${CTX}"; then
    echo "FAIL build: ${name}"
    failed=1
    continue
  fi

  cleanup
  echo "=== RUN ${name} ==="
  docker run -d --name pg-validate -e POSTGRES_PASSWORD="${PASS}" "validate/${name}:18" >/dev/null
  ready=0
  for _ in $(seq 1 30); do
    if docker exec pg-validate pg_isready -U postgres >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 1
  done
  if [ "${ready}" -ne 1 ]; then
    echo "FAIL startup: ${name}"
    docker logs pg-validate 2>&1 | tail -20
    failed=1
    cleanup
    continue
  fi

  actual=$(docker exec pg-validate psql -U postgres -d postgres -Atc \
    "SELECT extname FROM pg_extension ORDER BY extname;")
  missing=""
  for ext in ${expected}; do
    if ! printf '%s\n' "${actual}" | grep -qx "${ext}"; then
      missing="${missing} ${ext}"
    fi
  done
  if [ -n "${missing}" ]; then
    echo "FAIL extensions:${missing}"
    echo "  expected: ${expected}"
    echo "  actual:   $(echo "${actual}" | tr '\n' ' ')"
    failed=1
  else
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pg-validate)
    if [ -z "${container_ip}" ]; then
      echo "FAIL ssl: could not determine container IP for ${name}"
      failed=1
    elif docker exec pg-validate psql "postgresql://postgres:${PASS}@${container_ip}:5432/postgres?sslmode=disable" -c 'SELECT 1' >/dev/null 2>&1; then
      echo "FAIL ssl: non-SSL remote connection should be rejected for ${name}"
      failed=1
    elif ! docker exec pg-validate psql "postgresql://postgres:${PASS}@${container_ip}:5432/postgres?sslmode=require" -c 'SELECT 1' >/dev/null 2>&1; then
      echo "FAIL ssl: sslmode=require remote connection failed for ${name}"
      failed=1
    elif ! docker exec pg-validate psql "postgresql://postgres:${PASS}@127.0.0.1:5432/postgres?sslmode=disable" -c 'SELECT 1' >/dev/null 2>&1; then
      echo "FAIL ssl: local non-SSL connection failed for ${name}"
      failed=1
    else
      echo "OK ${name} -> ${expected} (ssl: remote require, local ok)"
    fi
  fi
  cleanup
done

if [ "${failed}" -ne 0 ]; then
  echo ""
  echo "Validation failed."
  exit 1
fi

echo ""
echo "All images built and passed extension checks."
