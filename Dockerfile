FROM extvos/alpine
MAINTAINER "Mingcai SHEN <archsh@gmail.com>"
ENV PG_MAJOR 9.5
ENV PG_VERSION 9.5.4
ENV LANG en_US.utf8

COPY entrypoint.sh /

RUN apk add ca-certificates \
    && apk add postgresql \
    && apk add postgresql-libs \
    && apk add postgresql-doc \
    && apk add postgresql-contrib \
    && apk add postgresql-clients \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" \
	&& chmod +x /usr/local/bin/gosu 

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql \
	&& chmod +x /entrypoint.sh

ENV PATH /usr/pgsql-$PG_MAJOR/bin:$PATH

ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]