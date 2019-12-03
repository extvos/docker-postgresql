FROM postgres:9.6-alpine
RUN apk update && apk add tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" >  /etc/timezone \
    && apk del tzdata \
    && apk add curl wget ca-certificates \
    && update-ca-certificates
COPY 10-config.sh /docker-entrypoint-initdb.d/
COPY 20-replication.sh /docker-entrypoint-initdb.d/
#USER postgres
