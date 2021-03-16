#!/bin/sh

export PGPASSWORD='senhadodb'

psql -h instanciateste.c5epvr8cs5qy.us-east-1.rds.amazonaws.com -p 5432 -U postgres -d teste -c "CREATE ROLE rds_pgaudit;"

aws rds modify-db-parameter-group \
   --db-parameter-group-name config-banco \
   --parameters "ParameterName=pgaudit.role,ParameterValue=rds_pgaudit,ApplyMethod=pending-reboot" \
   --region us-east-1

aws rds modify-db-parameter-group \
   --db-parameter-group-name config-banco \
   --parameters "ParameterName=shared_preload_libraries,ParameterValue=pgaudit,ApplyMethod=pending-reboot" \
   --region us-east-1

aws rds modify-db-parameter-group \
   --db-parameter-group-name config-banco \
   --parameters "ParameterName=pgaudit.log,ParameterValue=\"ddl,role\",ApplyMethod=pending-reboot" \
   --region us-east-1

aws rds modify-db-parameter-group \
   --db-parameter-group-name config-banco \
   --parameters "ParameterName=pgaudit.log_level,ParameterValue=info,ApplyMethod=pending-reboot" \
   --region us-east-1

aws rds modify-db-parameter-group \
   --db-parameter-group-name config-banco \
   --parameters "ParameterName=pgaudit.log_statement_once,ParameterValue=1,ApplyMethod=pending-reboot" \
   --region us-east-1

sleep 2m

aws rds reboot-db-instance \
    --db-instance-identifier instanciateste \
    --region us-east-1

sleep 3m

psql -h instanciateste.c5epvr8cs5qy.us-east-1.rds.amazonaws.com -p 5432 -U postgres -d teste -c "CREATE EXTENSION pgaudit;"

aws logs put-metric-filter \
  --log-group-name /aws/rds/instance/instanciateste/postgresql \
  --filter-name DeleteCount \
  --filter-pattern 'DELETE' \
  --metric-transformations \
      metricName=MetricaDelete,metricNamespace=MetricaDelete,metricValue=1,defaultValue=0

aws logs put-metric-filter \
  --log-group-name /aws/rds/instance/instanciateste/postgresql \
  --filter-name DropCount \
  --filter-pattern 'DROP' \
  --metric-transformations \
      metricName=MetricaDrop,metricNamespace=MetricaDrop,metricValue=1,defaultValue=0