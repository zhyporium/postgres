FROM postgres:18-bookworm
COPY common/install-timescale.sh /tmp/install-timescale.sh
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  gnupg curl ca-certificates \
  && bash /tmp/install-timescale.sh \
  && rm -rf /var/lib/apt/lists/* /tmp/install-timescale.sh
RUN echo "shared_preload_libraries = 'timescaledb,pg_stat_statements'" \
  >> /usr/share/postgresql/postgresql.conf.sample
COPY common/pg_hba.conf common/pg_hba.ssl.conf /usr/local/etc/postgresql/
COPY common/00-ssl.sh /docker-entrypoint-initdb.d/00-ssl.sh
COPY common/01-pg_hba.sh /docker-entrypoint-initdb.d/01-pg_hba.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-ssl.sh /docker-entrypoint-initdb.d/01-pg_hba.sh
COPY common/01-default-extensions.sql /docker-entrypoint-initdb.d/02-default-extensions.sql
COPY timescale/init.sql /docker-entrypoint-initdb.d/03-timescale.sql
