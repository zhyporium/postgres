#!/bin/bash
set -euo pipefail

case "${POSTGRES_SSL:-}" in
  1 | true | TRUE | on | ON | yes | YES)
    cp /usr/local/etc/postgresql/pg_hba.ssl.conf "${PGDATA}/pg_hba.conf"
    ;;
  *)
    cp /usr/local/etc/postgresql/pg_hba.conf "${PGDATA}/pg_hba.conf"
    ;;
esac
