FROM postgres:18-bookworm
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssl \
      postgresql-18-pgvector \
 && rm -rf /var/lib/apt/lists/*
RUN echo "shared_preload_libraries = 'pg_stat_statements'" \
  >> /usr/share/postgresql/postgresql.conf.sample
COPY common/pg_hba.conf /usr/local/etc/postgresql/pg_hba.conf
COPY common/00-ssl.sh /docker-entrypoint-initdb.d/00-ssl.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-ssl.sh
COPY common/01-default-extensions.sql /docker-entrypoint-initdb.d/01-default-extensions.sql
COPY pgvector/init.sql /docker-entrypoint-initdb.d/02-pgvector.sql
