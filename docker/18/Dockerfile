FROM postgres:18-bookworm
RUN echo "shared_preload_libraries = 'pg_stat_statements'" \
  >> /usr/share/postgresql/postgresql.conf.sample
COPY common/pg_hba.conf /usr/local/etc/postgresql/pg_hba.conf
COPY common/00-pg_hba.sh /docker-entrypoint-initdb.d/00-pg_hba.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-pg_hba.sh
COPY common/01-default-extensions.sql /docker-entrypoint-initdb.d/01-default-extensions.sql
