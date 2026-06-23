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

TLS is enabled with a self-signed certificate on first init. Remote connections require `sslmode=require`; only in-container localhost (socket / `127.0.0.1`) may connect without SSL.

Each variant folder includes a `.env.example` with `DATABASE_URL` for Prisma (`sslmode=require&schema=public`). If Prisma 7 fails on the self-signed cert, see the **Prisma** subsection in the root [`README.md`](../README.md#ssl).

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
