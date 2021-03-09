rm -rf $PGDATA
pg_basebackup -h pg_primary -U replicator -p 5432 -D $PGDATA -P -Xs -R