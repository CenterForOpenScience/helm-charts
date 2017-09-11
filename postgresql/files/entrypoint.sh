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
	-e "s|^conninfo='host=127.0.0.1 dbname=repmgr user=repmgr'|conninfo='host=${POD_NAME} dbname=${REPMGR_DBNAME}  user=${REPMGR_USER} password=${REPMGR_PASSWORD} application_name=node${ordinal_plus1}'|" \
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
	gosu postgres initdb --username=postgres "$POSTGRES_INITDB_ARGS"

	# check password first so we can output the warning before postgres
	# messes it up
	file_env 'POSTGRES_PASSWORD'
	if [ "$POSTGRES_PASSWORD" ]; then
		pass="PASSWORD '$POSTGRES_PASSWORD'"
		authMethod=md5
	else
		# The - option suppresses leading tabs but *not* spaces. :)
		cat >&2 <<-'EOWARN'
			****************************************************
			WARNING: No password has been set for the database.
					 This will allow anyone with access to the
					 Postgres port to access your database. In
					 Docker's default configuration, this is
					 effectively any other container on the same
					 system.

					 Use "-e POSTGRES_PASSWORD=password" to set
					 it in "docker run".
			****************************************************
		EOWARN

		pass=
		authMethod=trust
	fi

	# internal start of server in order to allow set-up using psql-client
	# does not listen on external TCP/IP and waits until start finishes
	PGUSER="${PGUSER:-postgres}" \
	gosu postgres pg_ctl -D "$PGDATA" -w start

	gosu postgres psql -c "CREATE USER repmgr SUPERUSER LOGIN ENCRYPTED PASSWORD '${REPMGR_PASSWORD}';"
	gosu postgres psql -c "CREATE DATABASE repmgr OWNER repmgr;"
	gosu postgres psql -c "CREATE USER barman SUPERUSER LOGIN ENCRYPTED PASSWORD '${BARMAN_PASSWORD}';"
	gosu postgres psql -c "CREATE USER barman_streaming REPLICATION LOGIN ENCRYPTED PASSWORD '${BARMAN_STREAMING_PASSWORD}';"
	gosu postgres psql -c "CREATE DATABASE barman OWNER barman;"

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

	gosu postgres pg_ctl -D "$PGDATA" -w restart

	# Master
	if [[ $ordinal -eq 0 ]]; then
		gosu postgres repmgr master register
	# Standby
	else
		if [[ ! -f "${PGDATA}/recovery.conf" ]]; then
			gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop
			rm -rf ${PGDATA}/*
			gosu postgres repmgr \
				--dbname="host=${master_host} dbname=${REPMGR_DBNAME} user=${REPMGR_USER} password=${REPMGR_PASSWORD} application_name=node1" \
				standby clone
			gosu postgres pg_ctl -D "$PGDATA" -w start
		fi

		gosu postgres repmgr standby register
	fi

	PGUSER="${PGUSER:-postgres}" \
	gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

	echo
	echo 'PostgreSQL init process complete; ready for start up.'
	echo
fi

echo
gosu postgres pg_ctl -D "$PGDATA" -w start
supervisorctl start repmgrd
