
psql -U postgres -c "ALTER SYSTEM SET listen_addresses TO '*'"

psql -U postgres -c "CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'secret'"

echo "host replication replicator all trust" >> $PGDATA/pg_hba.conf

psql -U postgres -x -c "select * from pg_stat_replication"