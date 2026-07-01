#!/bin/bash
set -euo pipefail

case "${POSTGRES_SSL:-}" in
  1 | true | TRUE | on | ON | yes | YES) ;;
  *) exit 0 ;;
esac

if [ -f "${PGDATA}/server.crt" ] && [ -f "${PGDATA}/server.key" ]; then
  :
else
  openssl req -new -x509 -days 3650 -nodes -subj "/CN=postgres" \
    -keyout "${PGDATA}/server.key" \
    -out "${PGDATA}/server.crt"

  chmod 600 "${PGDATA}/server.key"
  chmod 644 "${PGDATA}/server.crt"
fi

{
  echo "ssl = on"
  echo "ssl_cert_file = '${PGDATA}/server.crt'"
  echo "ssl_key_file = '${PGDATA}/server.key'"
} >> "${PGDATA}/postgresql.conf"
