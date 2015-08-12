FROM extvos/centos

MAINTAINER "Mingcai SHEN <archsh@gmail.com>"

ENV PG_MAJOR 9.4
ENV PG_VERSION 9.4.4-1PGDG
ENV LANG en_US.utf8

RUN yum install -y ca-certificates \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64.asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu 

RUN yum install -y http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-redhat94-9.4-1.noarch.rpm \
	&& yum install -y postgresql94-server postgresql94-contrib \
	&& mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]