#!/bin/bash
set -e

# List of required environment variables
required_vars=("SQLMESH_PORT_EXPOSE" "SQLMESH_PROJECT" "SERVER_NAME" "TRINO_USER" "TRINO_PASSWORD" "AIRFLOW_DB_USER" "AIRFLOW_DB_PASSWORD" "AIRFLOW_DB_NAME")

# Check if environment variables exist
missing_vars=false
for var in "${required_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "Error: Environment variable $var is not set."
    missing_vars=true
  fi
  #echo "Environment variable $var is set."
done

# If any required variable is missing, exit the script
if [ "$missing_vars" = true ]; then
  echo "Exiting script due to missing environment variables."
  exit 1
fi

# Start SQLMesh server
mkdir -p /opt/sqlmesh/${SQLMESH_PROJECT}
cd /opt/sqlmesh/${SQLMESH_PROJECT}
if ! sqlmesh init trino; then
  echo 'SQLMesh init trino failed, but continuing'
fi

# All required environment variables are set, proceed with sed
sed -e "s|\${SERVER_NAME}|${SERVER_NAME}|g" \
    -e "s|\${TRINO_USER}|${TRINO_USER}|g" \
    -e "s|\${TRINO_PASSWORD}|${TRINO_PASSWORD}|g" \
    -e "s|\${AIRFLOW_DB_USER}|${AIRFLOW_DB_USER}|g" \
    -e "s|\${AIRFLOW_DB_PASSWORD}|${AIRFLOW_DB_PASSWORD}|g" \
    -e "s|\${AIRFLOW_DB_NAME}|${AIRFLOW_DB_NAME}|g" \
    /etc/sqlmesh/template/config.yaml.template > /opt/sqlmesh/${SQLMESH_PROJECT}/config.yaml
# for Test
cp /etc/sqlmesh/template/config.yaml /opt/sqlmesh/${SQLMESH_PROJECT}/config.yaml

echo "Configuration file generated successfully!"

sqlmesh ui --host 0.0.0.0 --port ${SQLMESH_PORT_EXPOSE}
#sqlmesh migrate-to-dbt --project-dir /opt/sqlmesh/trino_test --output-dir /opt/sqlmesh/trino_test_dbt
