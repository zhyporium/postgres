#!/bin/bash
set -euo pipefail

if [ -f "${PGDATA}/server.crt" ] && [ -f "${PGDATA}/server.key" ]; then
  exit 0
fi

openssl req -new -x509 -days 3650 -nodes -subj "/CN=postgres" \
  -keyout "${PGDATA}/server.key" \
  -out "${PGDATA}/server.crt"

chmod 600 "${PGDATA}/server.key"
chmod 644 "${PGDATA}/server.crt"

{
  echo "ssl = on"
  echo "ssl_cert_file = '${PGDATA}/server.crt'"
  echo "ssl_key_file = '${PGDATA}/server.key'"
} >> "${PGDATA}/postgresql.conf"

cp /usr/local/etc/postgresql/pg_hba.conf "${PGDATA}/pg_hba.conf"
