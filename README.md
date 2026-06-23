# Postgres 18 (Debian)

PostgreSQL 18 Docker images built on `postgres:18-bookworm`, published to GitHub Container Registry under a single package with variant tags.

## Images

All images are published as:

```text
ghcr.io/zhyporium/postgres:<tag>
```

| Tag            | Variant                | Extra extensions        |
| -------------- | ---------------------- | ----------------------- |
| `18`           | Vanilla Postgres 18    | —                       |
| `18_pgvector`  | pgvector               | `vector`                |
| `18_timescale` | TimescaleDB            | `timescaledb`           |
| `18_vt`        | pgvector + TimescaleDB | `vector`, `timescaledb` |

### Included on every variant

These are enabled automatically on first database init:

- `pg_stat_statements` (preloaded)
- `pg_trgm`
- `unaccent`

Variant-specific extensions are created via init SQL in `/docker-entrypoint-initdb.d/`. Init scripts only run on a **fresh** data directory.

## Pull and run

```bash
docker pull ghcr.io/zhyporium/postgres:18
docker pull ghcr.io/zhyporium/postgres:18_pgvector
docker pull ghcr.io/zhyporium/postgres:18_timescale
docker pull ghcr.io/zhyporium/postgres:18_vt

docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=yourpassword \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql \
  ghcr.io/zhyporium/postgres:18_pgvector
```

Connect:

```bash
psql "postgresql://postgres:yourpassword@localhost:5432/postgres"
```

## When to use which variant

| Tag            | Use case                                                          |
| -------------- | ----------------------------------------------------------------- |
| `18`           | General-purpose OLTP / app databases                              |
| `18_pgvector`  | Semantic search, embeddings, RAG                                  |
| `18_timescale` | Time-series metrics, IoT, events queried by time range            |
| `18_vt`        | Apps that need both vector search and time-series in one database |

## Local build

Build context for all variants is `docker/18`:

```bash
docker build -f docker/18/Dockerfile -t postgres:18 docker/18
docker build -f docker/18/pgvector/Dockerfile -t postgres:18_pgvector docker/18
docker build -f docker/18/timescale/Dockerfile -t postgres:18_timescale docker/18
docker build -f docker/18/pgvector-timescale/Dockerfile -t postgres:18_vt docker/18
```

## Validate locally

Build, start, and check extensions for every variant:

```bash
./scripts/validate-images.sh
```

## CI/CD

GitHub Actions builds and pushes **multi-arch** images (`linux/amd64`, `linux/arm64`) to GHCR. Each variant has its own workflow under [`.github/workflows/`](.github/workflows/); only changed images are rebuilt on push to `main`.

| Workflow                                | Triggers on                                              |
| --------------------------------------- | -------------------------------------------------------- |
| `build-postgres.yml`                    | `docker/18/Dockerfile`, `docker/18/common/**`            |
| `build-postgres-pgvector.yml`           | `docker/18/pgvector/**`, `docker/18/common/**`           |
| `build-postgres-timescale.yml`          | `docker/18/timescale/**`, `docker/18/common/**`          |
| `build-postgres-pgvector-timescale.yml` | `docker/18/pgvector-timescale/**`, `docker/18/common/**` |

Workflows can also be run manually via **workflow_dispatch**.

## Project layout

```text
docker/18/
├── Dockerfile                 # vanilla (tag: 18)
├── common/
│   └── 01-default-extensions.sql
├── pgvector/
├── timescale/
└── pgvector-timescale/        # tag: 18_vt

.github/workflows/             # per-variant CI
scripts/validate-images.sh     # local smoke tests
```

## License

[MIT](LICENSE) — Dockerfiles and scripts in this repository.

Bundled software (PostgreSQL, pgvector, TimescaleDB, etc.) remains under its respective upstream licenses.
