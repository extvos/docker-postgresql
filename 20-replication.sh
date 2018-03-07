#!/bin/bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# common settings
file_env 'MAX_CONNECTIONS' 500
file_env 'WAL_KEEP_SEGMENTS' 256
file_env 'MAX_WAL_SENDERS' 100

# master/slave settings
file_env 'REPLICATION_ROLE' 'master'
file_env 'REPLICATION_USER' 'replication'
file_env 'REPLICATION_PASSWORD' ""
file_env 'REPLICATION_NETWORK' '0.0.0.0/0'

# slave settings
ENV 'POSTGRES_MASTER_HOST' 'localhost'
ENV 'POSTGRES_MASTER_PORT' 5432

if [ $REPLICATION_ROLE = "master" ]; then
    psql -U postgres -c "CREATE ROLE $REPLICATION_USER WITH REPLICATION PASSWORD '$REPLICATION_PASSWORD' LOGIN"
elif [ $REPLICATION_ROLE = "slave" ]; then
    # stop postgres instance and reset PGDATA,
    # confs will be copied by pg_basebackup
    pg_ctl -D "$PGDATA" -m fast -w stop
    # make sure standby's data directory is empty
    rm -r "$PGDATA"/*

    pg_basebackup \
         --write-recovery-conf \
         --pgdata="$PGDATA" \
         --xlog-method=fetch \
         --username=$REPLICATION_USER \
         --host=$POSTGRES_MASTER_HOST \
         --port=$POSTGRES_MASTER_PORT \
         --progress \
         --verbose

    # useless postgres start to fullfil docker-entrypoint.sh stop
    pg_ctl -D "$PGDATA" \
         -o "-c listen_addresses=''" \
         -w start
fi

echo [*] $REPLICATION_ROLE instance configured!
