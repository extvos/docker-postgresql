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
file_env 'POSTGRES_MASTER_HOST' 'localhost'
file_env 'POSTGRES_MASTER_PORT' 5432

echo [*] configuring $REPLICATION_ROLE instance

echo "max_connections = $MAX_CONNECTIONS" >> "$PGDATA/postgresql.conf"

# We set master replication-related parameters for both slave and master,
# so that the slave might work as a primary after failover.
echo "wal_level = hot_standby" >> "$PGDATA/postgresql.conf"
echo "wal_keep_segments = $WAL_KEEP_SEGMENTS" >> "$PGDATA/postgresql.conf"
echo "max_wal_senders = $MAX_WAL_SENDERS" >> "$PGDATA/postgresql.conf"
# slave settings, ignored on master
echo "hot_standby = on" >> "$PGDATA/postgresql.conf"


echo "host replication $REPLICATION_USER $REPLICATION_NETWORK trust" >> "$PGDATA/pg_hba.conf"
