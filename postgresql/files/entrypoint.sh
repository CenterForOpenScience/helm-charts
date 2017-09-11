#!/bin/bash
set -e

[[ $POD_NAME =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}
ordinal_plus1=$((${ordinal} + 1))
master_host=$(echo -n ${POD_NAME} | sed -E 's|-[0-9]+$|-0|')
if [ "$MASTER_HOST" ]; then
	master_host=${MASTER_HOST}
fi

sed \
	-e "s|^#node=2|node=${ordinal_plus1}|" \
	-e "s|^#node_name=node2|node_name=node${ordinal_plus1}|" \
	-e "s|^conninfo=.*$|conninfo='host=${POD_NAME} dbname=repmgr user=repmgr password=${REPMGR_PASSWORD} application_name=node${ordinal_plus1}'|" \
	/etc/_repmgr.conf > /etc/repmgr.conf

# usage: file_env VAR [DEFAULT]
#	ie: file_env 'XYZ_DB_PASSWORD' 'example'
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

if [ "${1:0:1}" = '-' ]; then
	set -- postgres "$@"
fi

mkdir -p "$PGDATA"
chown -R postgres "$PGDATA"
chmod 700 "$PGDATA"

mkdir -p /var/run/postgresql
chown -R postgres /var/run/postgresql
chmod g+s /var/run/postgresql

# Create the transaction log directory before initdb is run (below) so the directory is owned by the correct user
if [ "$POSTGRES_INITDB_XLOGDIR" ]; then
	mkdir -p "$POSTGRES_INITDB_XLOGDIR"
	chown -R postgres "$POSTGRES_INITDB_XLOGDIR"
	chmod 700 "$POSTGRES_INITDB_XLOGDIR"
fi

# look specifically for PG_VERSION, as it is expected in the DB dir
if [ ! -s "$PGDATA/PG_VERSION" ]; then
	file_env 'POSTGRES_INITDB_ARGS'
	if [ "$POSTGRES_INITDB_XLOGDIR" ]; then
		export POSTGRES_INITDB_ARGS="$POSTGRES_INITDB_ARGS --xlogdir $POSTGRES_INITDB_XLOGDIR"
	fi
	gosu postgres initdb --username=${PGUSER} "$POSTGRES_INITDB_ARGS"

	gosu postgres pg_ctl -w start

	gosu postgres psql <<-EOF
	CREATE USER repmgr SUPERUSER LOGIN ENCRYPTED PASSWORD '${REPMGR_PASSWORD}';
	CREATE DATABASE repmgr OWNER repmgr;
	CREATE USER barman SUPERUSER LOGIN ENCRYPTED PASSWORD '${BARMAN_PASSWORD}';
	CREATE USER barman_streaming REPLICATION LOGIN ENCRYPTED PASSWORD '${BARMAN_STREAMING_PASSWORD}';
	CREATE DATABASE barman OWNER barman;
	EOF

	sed -i \
		-e "s|^listen_addresses = .*|listen_addresses = '*'|" \
		-e "s|^#hot_standby = .*|hot_standby = on|" \
		-e "s|^#wal_level = .*|wal_level = hot_standby|" \
		-e "s|^#max_wal_senders = .*|max_wal_senders = 10|" \
		-e "s|^#max_replication_slots = .*|max_replication_slots = 10|" \
		-e "s|^#archive_mode = .*|archive_mode = on|" \
		-e "s|^#archive_command = .*|archive_command = '/bin/true'|" \
		-e "s|^#shared_preload_libraries = .*|shared_preload_libraries = 'repmgr_funcs'|" \
		${PGDATA}/postgresql.conf

	cidr_range="$(echo -n $POD_IP | grep -oE '^[0-9]+\.')0.0.0/8"

	cat >> ${PGDATA}/pg_hba.conf <<-EOF
	host    repmgr          repmgr           all                   md5
	host    replication     repmgr           all                   md5
	host    barman          barman           all                   md5
	host    replication     barman_streaming all                   md5
	# other
	host    all             all              ${cidr_range}         md5
	EOF

	gosu postgres pg_ctl -w restart

	# Master
	if [[ $ordinal -eq 0 ]] || [[ $POD_NAME == $master_host ]]; then
		gosu postgres repmgr master register
	# Standby
	else
		if [[ ! -f "${PGDATA}/recovery.conf" ]]; then
			gosu postgres pg_ctl -m fast -w stop
			rm -rf ${PGDATA}/*
			gosu postgres repmgr \
				--dbname="host=${master_host} dbname=repmgr user=repmgr password=${REPMGR_PASSWORD}" \
				standby clone
			gosu postgres pg_ctl -w start
		fi

		gosu postgres repmgr standby register
	fi
else
	gosu postgres pg_ctl -w start
fi

supervisorctl start repmgrd
