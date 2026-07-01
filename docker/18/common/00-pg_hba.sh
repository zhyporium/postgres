#!/bin/bash
set -euo pipefail

cp /usr/local/etc/postgresql/pg_hba.conf "${PGDATA}/pg_hba.conf"
