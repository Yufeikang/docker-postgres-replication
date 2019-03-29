# -*- mode: conf -*-
FROM postgres:11.2-alpine

MAINTAINER me@nebirhos.com

# common settings
ENV MAX_CONNECTIONS 500
ENV WAL_KEEP_SEGMENTS 256
ENV MAX_WAL_SENDERS 100

# master/slave settings
ENV REPLICATION_ROLE master
ENV REPLICATION_USER replication
ENV REPLICATION_PASSWORD ""

# slave settings
ENV POSTGRES_MASTER_SERVICE_HOST localhost
ENV POSTGRES_MASTER_SERVICE_PORT 5432

COPY 10-config.sh /docker-entrypoint-initdb.d/
COPY 20-replication.sh /docker-entrypoint-initdb.d/
# Evaluate vars inside PGDATA at runtime.
# For example HOSTNAME in 'ENV PGDATA=/mnt/$HOSTNAME'
# is resolved runtime rather then during build

RUN apk add --no-cache --virtual .build-deps \
        gcc \
		libc-dev \
		make \
    && cd ~ \
    && wget -O scws-1.2.2.tar.bz2 http://www.xunsearch.com/scws/down/scws-1.2.2.tar.bz2  \
    && tar xf scws-1.2.2.tar.bz2 \
    && cd scws-1.2.2 \
    && ./configure \
    && make install \ 
    && cd ~ \
    && wget -O zhparser.tar.gz https://github.com/amutu/zhparser/archive/v0.2.0.tar.gz  \
    && tar zxf zhparser.tar.gz \
    && cd zhparser-0.2.0 \
    && SCWS_HOME=/usr/local make && make install \
    && cd ~ \
    && rm -rf scws-1.2.2* zhparser* \
    && apk del .build-deps 

RUN sed -i 's/set -e/set -e -x\nPGDATA=$(eval echo "$PGDATA")/' /docker-entrypoint.sh
