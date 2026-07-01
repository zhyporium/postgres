FROM postgres:18-bookworm
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  postgresql-18-pgvector \
  && rm -rf /var/lib/apt/lists/*
RUN echo "shared_preload_libraries = 'pg_stat_statements'" \
  >> /usr/share/postgresql/postgresql.conf.sample
COPY common/pg_hba.conf common/pg_hba.ssl.conf /usr/local/etc/postgresql/
COPY common/00-ssl.sh /docker-entrypoint-initdb.d/00-ssl.sh
COPY common/01-pg_hba.sh /docker-entrypoint-initdb.d/01-pg_hba.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-ssl.sh /docker-entrypoint-initdb.d/01-pg_hba.sh
COPY common/01-default-extensions.sql /docker-entrypoint-initdb.d/02-default-extensions.sql
COPY pgvector/init.sql /docker-entrypoint-initdb.d/03-pgvector.sql
