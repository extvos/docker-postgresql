FROM postgres:9.6-alpine
RUN apk update && apk add tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" >  /etc/timezone \
    && apk del tzdata \
    && apk add curl wget ca-certificates \
    && update-ca-certificates
RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps ca-certificates openssl tar \
    && wget -q -O - "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - \
    && wget -O zhparser.zip "https://github.com/amutu/zhparser/archive/master.zip" \
    && wget -O postgresql.tar.bz2 "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2" \
    && echo "$PG_SHA256 *postgresql.tar.bz2" | sha256sum -c - \
    && mkdir -p /usr/src/postgresql \
    && tar \
        --extract \
        --file postgresql.tar.bz2 \
        --directory /usr/src/postgresql \
        --strip-components 1 \
    && rm postgresql.tar.bz2 \
    \
    && apk add --no-cache --virtual .build-deps gcc libc-dev make \
    && cd /scws-1.2.3 \
    && ./configure \
    && make install \
    && cd / \
    && unzip zhparser.zip \
    && cd /zhparser-master \
    && SCWS_HOME=/usr/local make && make install \
# pg_trgm is recommend but not required.
    && echo -e "CREATE EXTENSION pg_trgm; \n\
CREATE EXTENSION zhparser VERSION '2.1'; \n\
CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser); \n\
ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l,t WITH simple;" \
> /docker-entrypoint-initdb.d/init-zhparser.sql \
    && apk del .build-deps .fetch-deps \
    && rm -rf \
        /usr/src/postgresql \
        /zhparser-master \
        /zhparser.zip \
    /scws-1.2.3 \
    && find /usr/local -name '*.a' -delete
COPY 10-config.sh /docker-entrypoint-initdb.d/
COPY 20-replication.sh /docker-entrypoint-initdb.d/
#USER postgres
