#!/usr/bin/env bash
set -e

if [ "$1" = 'postgres' ]; then
	[[ ${POD_NAME} =~ -([0-9]+)$ ]] || exit 1
	ordinal=${BASH_REMATCH[1]}
	if [ $STATEFUL_TYPE == "master" ]; then
		node_id=$((${ordinal} + 1))
		service=${MASTER_SERVICE}
	else
		node_id=$((${ordinal} + 100))
		service=${POD_NAME}
	fi

	sed \
		-e "s|^#cluster=.*$|cluster=default|" \
		-e "s|^#node=.*$|node=${node_id}|" \
		-e "s|^#node_name=.*$|node_name=${POD_NAME}|" \
		-e "s|^#conninfo=.*$|conninfo='host=${service} dbname=repmgr user=repmgr password=${REPMGR_PASSWORD} application_name=repmgrd'|" \
		-e "s|^#use_replication_slots=.*$|use_replication_slots=1|" \
		/etc/repmgr.conf.tpl > /etc/repmgr.conf

	if [ ! -s "$PGDATA/PG_VERSION" ]; then
		if [ $STATEFUL_TYPE == "master" ]; then
			exec docker-entrypoint.sh "$@" &

			while ! pg_isready --host ${POD_IP} --quiet
			do
				sleep 1
			done

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
			
			if [ -n "${SSL_ENABLED}" ]; then
				sed -i \
					-e "s|^#ssl = .*|ssl = on|" \
					-e "s|^#ssl_ciphers = .*|ssl_ciphers = 'HIGH'|" \
					-e "s|^#ssl_cert_file = .*|ssl_cert_file = '/etc/ssl/server.crt'|" \
					-e "s|^#ssl_key_file = .*|ssl_key_file = '/etc/ssl/server.key'|" \
					-e "s|^#ssl_ca_file = .*|ssl_ca_file = '/etc/ssl/ca.crt'|" \
					-e "s|^#ssl_crl_file = .*|ssl_crl_file = '/etc/ssl/ca.crl'|" \
					${PGDATA}/postgresql.conf

				sed -i \
					-E "s|^host([ \\t]+all){3}.*|hostssl   all   all   all   md5   clientcert=1|" \
					${PGDATA}/pg_hba.conf
			fi

			gosu postgres psql <<-EOF
			CREATE USER repmgr SUPERUSER LOGIN ENCRYPTED PASSWORD '${REPMGR_PASSWORD}';
			CREATE DATABASE repmgr OWNER repmgr;
			EOF

			cat >> ${PGDATA}/pg_hba.conf <<-EOF

			# repmgr
			host    repmgr          repmgr           all                   md5
			host    replication     repmgr           all                   md5
			EOF

			gosu postgres pg_ctl reload

			while ! pg_isready --host ${MASTER_SERVICE}
			do
				sleep 1
			done

			gosu postgres repmgr master register

			gosu postgres psql -U repmgr -d repmgr <<-EOF
			ALTER TABLE repmgr_default.repl_monitor SET UNLOGGED;
			EOF
		else
			while ! pg_isready --host ${MASTER_SERVICE}
			do
				sleep 1
			done

			mkdir -p "$PGDATA"
			chown -R postgres "$PGDATA"
			chmod 700 "$PGDATA"

			gosu postgres repmgr \
				--dbname="host=${MASTER_SERVICE} dbname=repmgr user=repmgr password=${REPMGR_PASSWORD}" \
				standby clone

			gosu postgres pg_ctl -w start

			while ! pg_isready --host ${POD_NAME} --quiet
			do
				sleep 1
			done

			gosu postgres repmgr standby register
		fi

		gosu postgres pg_ctl -w stop
		exit 0
	fi

	exec docker-entrypoint.sh "$@" & pid=$!

	while ! pg_isready --host ${service} --quiet
	do
		sleep 1
	done

	supervisorctl start repmgrd

	wait ${pid}
	exit 0
fi

if [ "$1" = 'repmgrd' ] && [ "$(id -u)" = '0' ]; then
	exec gosu postgres "$@"
fi

if [ "$1" = 'cleanup' ]; then
	while true
	do
		sleep 3600

		if pg_isready --host ${MASTER_SERVICE} --quiet; then
			gosu postgres repmgr --keep-history=1 cluster cleanup
		fi
	done
fi

exec "$@"
