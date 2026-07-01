# Compose examples

Reference deploy templates for running published images from GHCR. These files are **not** built or pushed by CI — they pull `ghcr.io/zhyporium/postgres` at runtime.

## Variants

| Folder                                                 | Image tag      | Use case                   |
| ------------------------------------------------------ | -------------- | -------------------------- |
| [`18/compose.yml`](18/compose.yml)                     | `18`           | General-purpose Postgres   |
| [`18_pgvector/compose.yml`](18_pgvector/compose.yml)   | `18_pgvector`  | Vector search / embeddings |
| [`18_timescale/compose.yml`](18_timescale/compose.yml) | `18_timescale` | Time-series data           |
| [`18_vt/compose.yml`](18_vt/compose.yml)               | `18_vt`        | pgvector + TimescaleDB     |

Every variant includes `pg_stat_statements`, `pg_trgm`, and `unaccent` on first init.

TLS is enabled with a self-signed certificate on first init. Host connections via a published port should use `sslmode=require`. Sibling services on the same Compose network can connect without SSL (e.g. `postgresql://postgres:password@postgres:5432/postgres`). In-container localhost (socket / `127.0.0.1`) may also connect without SSL.

Each variant folder includes a `.env.example` with `DATABASE_URL` for Prisma when connecting from the host (`sslmode=require&schema=public`). For an app service in the same Compose file, point `DATABASE_URL` at the service name and omit `sslmode=require`. If Prisma 7 fails on the self-signed cert from the host, see the **Prisma** subsection in the root [`README.md`](../README.md#ssl).

## Run

Pick a variant folder, copy env defaults, then start:

```bash
cd examples/18_pgvector
cp .env.example .env   # edit POSTGRES_PASSWORD before production use
docker compose up -d
```

Connect:

```bash
psql "postgresql://postgres:postgres@localhost:5432/postgres?sslmode=require"
```

Stop and remove:

```bash
docker compose down
```

To wipe data:

```bash
docker compose down -v
```
