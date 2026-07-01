#!/bin/bash
set -euo pipefail

mkdir -p /etc/apt/keyrings
curl -fsSL https://packagecloud.io/timescale/timescaledb/gpgkey \
  | gpg --dearmor -o /etc/apt/keyrings/timescaledb.gpg
echo "deb [signed-by=/etc/apt/keyrings/timescaledb.gpg] https://packagecloud.io/timescale/timescaledb/debian/ bookworm main" \
  > /etc/apt/sources.list.d/timescaledb.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends timescaledb-2-postgresql-18
