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

### SSL

On first init, each image generates a self-signed certificate and enables TLS. Remote TCP connections require SSL (`hostssl` only); local connections via Unix socket or `127.0.0.1` / `::1` inside the container may use non-SSL.

```bash
psql "postgresql://postgres:yourpassword@localhost:5432/postgres?sslmode=require"
```

Note: traffic from your host to a published Docker port is not seen as localhost inside the container — use `sslmode=require` there too. Use `sslmode=verify-full` only if you mount your own CA-trusted certificates.

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
psql "postgresql://postgres:yourpassword@localhost:5432/postgres?sslmode=require"
```

## When to use which variant

| Tag            | Use case                                                          |
| -------------- | ----------------------------------------------------------------- |
| `18`           | General-purpose OLTP / app databases                              |
| `18_pgvector`  | Semantic search, embeddings, RAG                                  |
| `18_timescale` | Time-series metrics, IoT, events queried by time range            |
| `18_vt`        | Apps that need both vector search and time-series in one database |

## Examples

Docker Compose templates for each variant live in [`examples/`](examples/). Each folder pulls a published GHCR image — nothing is built locally.

```bash
cd examples/18_vt
cp .env.example .env
docker compose up -d
```

See [`examples/README.md`](examples/README.md) for the full list (`18`, `18_pgvector`, `18_timescale`, `18_vt`).

## Local build

Build context for all variants is `docker/18`:

```bash
docker build -f docker/18/Dockerfile -t postgres:18 docker/18
docker build -f docker/18/pgvector/Dockerfile -t postgres:18_pgvector docker/18
docker build -f docker/18/timescale/Dockerfile -t postgres:18_timescale docker/18
docker build -f docker/18/pgvector-timescale/Dockerfile -t postgres:18_vt docker/18
```

## Validate locally

Build, start, and check extensions and SSL policy for every variant:

```bash
./scripts/validate-images.sh
```

The script verifies extensions, rejects non-SSL remote TCP, accepts `sslmode=require` over the container network IP, and still allows local non-SSL on `127.0.0.1`.

**Existing data volumes are not reconfigured** when you pull a newer image. SSL certs, `pg_hba.conf`, and init extensions only apply on first init. To pick up changes from this repo on an existing deployment, recreate the volume or apply the config manually.

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
│   ├── 00-ssl.sh                # self-signed TLS + pg_hba on first init
│   ├── pg_hba.conf
│   └── 01-default-extensions.sql
├── pgvector/
├── timescale/
└── pgvector-timescale/        # tag: 18_vt

examples/                      # compose templates (GHCR pull)
├── 18/compose.yml
├── 18_pgvector/compose.yml
├── 18_timescale/compose.yml
└── 18_vt/compose.yml

.github/workflows/             # per-variant CI
scripts/validate-images.sh     # local smoke tests
```

## License

[MIT](LICENSE) — Dockerfiles and scripts in this repository.

Bundled software (PostgreSQL, pgvector, TimescaleDB, etc.) remains under its respective upstream licenses.
