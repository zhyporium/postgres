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
  docker rm -f pg-validate pg-validate-client >/dev/null 2>&1 || true
  docker network rm pg-validate-net >/dev/null 2>&1 || true
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
  docker network create pg-validate-net >/dev/null
  echo "=== RUN ${name} ==="
  docker run -d --name pg-validate --network pg-validate-net -e POSTGRES_PASSWORD="${PASS}" "validate/${name}:18" >/dev/null
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

  actual=$(docker exec pg-validate psql "postgresql://postgres:${PASS}@127.0.0.1:5432/postgres" -Atc \
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
    if ! docker run --rm --network pg-validate-net "validate/${name}:18" \
      psql "postgresql://postgres:${PASS}@pg-validate:5432/postgres" -c 'SELECT 1' >/dev/null 2>&1; then
      echo "FAIL connect: sibling container connection failed for ${name}"
      failed=1
    elif ! docker exec pg-validate psql "postgresql://postgres:${PASS}@127.0.0.1:5432/postgres" -c 'SELECT 1' >/dev/null 2>&1; then
      echo "FAIL connect: local connection failed for ${name}"
      failed=1
    else
      echo "OK ${name} -> ${expected}"
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
echo "=== SSL optional (postgres) ==="
cleanup
docker network create pg-validate-net >/dev/null
docker run -d --name pg-validate --network pg-validate-net \
  -e POSTGRES_PASSWORD="${PASS}" -e POSTGRES_SSL=1 \
  "validate/postgres:18" >/dev/null
ready=0
for _ in $(seq 1 30); do
  if docker exec pg-validate pg_isready -U postgres >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [ "${ready}" -ne 1 ]; then
  echo "FAIL startup: postgres with POSTGRES_SSL=1"
  docker logs pg-validate 2>&1 | tail -20
  failed=1
else
  ssl_state=$(docker exec pg-validate psql "postgresql://postgres:${PASS}@127.0.0.1:5432/postgres" -Atc "SHOW ssl;")
  if [ "${ssl_state}" != "on" ]; then
    echo "FAIL ssl: expected on, got ${ssl_state}"
    failed=1
  elif ! docker exec pg-validate psql "postgresql://postgres:${PASS}@127.0.0.1:5432/postgres?sslmode=require" -c 'SELECT 1' >/dev/null 2>&1; then
    echo "FAIL ssl: sslmode=require connection failed"
    failed=1
  elif ! docker run --rm --network pg-validate-net "validate/postgres:18" \
    psql "postgresql://postgres:${PASS}@pg-validate:5432/postgres" -c 'SELECT 1' >/dev/null 2>&1; then
    echo "FAIL ssl: plain sibling container connection failed"
    failed=1
  else
    echo "OK postgres SSL enabled with mixed-mode internal access"
  fi
fi
cleanup

if [ "${failed}" -ne 0 ]; then
  echo ""
  echo "Validation failed."
  exit 1
fi

echo ""
echo "All images built and passed extension checks."
