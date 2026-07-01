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

Each variant folder includes a `.env.example` with a Prisma `DATABASE_URL`. From another Compose service, use the service hostname (`postgres`); from the host, use `localhost`.

## Run

Pick a variant folder, copy env defaults, then start:

```bash
cd examples/18_pgvector
cp .env.example .env   # edit POSTGRES_PASSWORD before production use
docker compose up -d
```

Connect:

```bash
psql "postgresql://postgres:postgres@localhost:5432/postgres"
```

Stop and remove:

```bash
docker compose down
```

To wipe data:

```bash
docker compose down -v
```
