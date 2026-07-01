FROM postgres:18-bookworm
RUN apt-get update \
     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
     gnupg curl ca-certificates lsb-release \
     && curl -sSf https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | bash \
     && apt-get update \
     && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
     postgresql-18-pgvector \
     timescaledb-2-postgresql-18 \
     && rm -rf /var/lib/apt/lists/*
RUN echo "shared_preload_libraries = 'timescaledb,pg_stat_statements'" \
     >> /usr/share/postgresql/postgresql.conf.sample
COPY common/pg_hba.conf /usr/local/etc/postgresql/pg_hba.conf
COPY common/00-pg_hba.sh /docker-entrypoint-initdb.d/00-pg_hba.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-pg_hba.sh
COPY common/01-default-extensions.sql /docker-entrypoint-initdb.d/01-default-extensions.sql
COPY pgvector-timescale/init.sql /docker-entrypoint-initdb.d/02-pgvector-timescale.sql
