FROM postgres:18-bookworm
RUN echo "shared_preload_libraries = 'pg_stat_statements'" \
  >> /usr/share/postgresql/postgresql.conf.sample
COPY common/01-default-extensions.sql /docker-entrypoint-initdb.d/01-default-extensions.sql
