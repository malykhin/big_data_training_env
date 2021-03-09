hadoop_cf    		  = docker-compose.hadoop.yml
hive_cf 		  		= docker-compose.hive.yml
spark_cf		 		  = docker-compose.spark.yml
airflow_cf   		  = docker-compose.airflow.yml
aws_cf			 		  = docker-compose.aws.yml
postgres_repl_cf  = docker-compose.postgresql_replication.yml
postgres_shard_cf = docker-compose.postgresql_sharding.yml
superset_cf			  = docker-compose.superset.yml

REQUIRED_BINS := docker docker-compose python


postgres_repl:
		docker-compose -f $(postgres_repl_cf) up -d 

postgres_shard:
		docker-compose -f $(postgres_shard_cf) up -d

hadoop:
		docker-compose -f $(hadoop_cf) up -d 

hive:
		docker-compose -f $(hive_cf) up -d

hadoop_hive:
		docker-compose -f $(hadoop_cf) -f $(hive_cf) up -d 

spark:
		docker-compose -f $(spark_cf) up -d

airflow:
		docker-compose -f $(airflow_cf) up -d

airflow_practice:
		docker-compose -f $(postgres_repl_cf) -f $(aws_cf) -f $(airflow_cf) -f $(hadoop_cf) up -d

aws:
		docker-compose -f $(aws_cf) up -d

superset:
		docker-compose -f $(superset_cf) up -d

superset_postgres:
		docker-compose -f $(superset_cf) -f $(postgres_repl_cf) up -d

spark_atirlow:
		docker-compose -f $(spark_cf) -f $(airflow_cf) up -d

hadoop_airflow:
		docker-compose -f $(hadoop_cf) -f $(airflow_cf) up -d

hadoop_spark:
		docker-compose -f $(hadoop_cf) -f $(spark_cf) up -d

hadoop_spark_atirlow:
		docker-compose -f $(hadoop_cf) -f $(spark_cf) -f $(airflow_cf) up -d

start_all:
		docker-compose -f $(spark_cf) -f $(hadoop_cf) -f $(airflow_cf) -f $(aws_cf) -f $(superset_cf) -f $(postgres_repl_cf) -f $(hive_cf) up -d

stop_all:
		docker-compose -f $(spark_cf) -f $(hadoop_cf) -f $(airflow_cf) -f $(aws_cf) -f $(postgres_repl_cf) -f $(postgres_shard_cf) -f $(superset_cf) -f $(hive_cf) down

cleanup_volumes:
		docker volume rm $$(docker volume ls -q)
		