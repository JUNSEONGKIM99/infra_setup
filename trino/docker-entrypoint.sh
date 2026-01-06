#!/bin/bash
set -e

# List of required environment variables
required_vars=("OLTP_JDBC_URL" "OLTP_DB_USER" "OLTP_DB_PASSWORD" "HIVE_METASTORE_URI" \
  "ICE_DB_NAME" "ICE_JDBC_URL" "ICE_DB_USER" "ICE_DB_PASSWORD" "ICEBERG_DIR" \
  "MINIO_ENDPOINT" "MINIO_ACCESS_KEY" "MINIO_SECRET_KEY")

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

# All required environment variables are set, proceed with sed
sed -e "s|\${OLTP_JDBC_URL}|${OLTP_JDBC_URL}|g" \
    -e "s|\${OLTP_DB_USER}|${OLTP_DB_USER}|g" \
    -e "s|\${OLTP_DB_PASSWORD}|${OLTP_DB_PASSWORD}|g" \
    /etc/trino/template/postgresql.properties.template > /etc/trino/catalog/postgresql.properties

# sed -e "s|\${RAW_JDBC_URL1}|${RAW_JDBC_URL1}|g" \
#     -e "s|\${RAW_JDBC_URL2}|${RAW_JDBC_URL2}|g" \
#     -e "s|\${RAW_DB_USER}|${RAW_DB_USER}|g" \
#     -e "s|\${RAW_DB_PASSWORD}|${RAW_DB_PASSWORD}|g" \
#     /etc/trino/template/mssql_mes_sft.properties.template > /etc/trino/catalog/mssql_mes_sft.properties

# sed -e "s|\${RAW_JDBC_URL1}|${RAW_JDBC_URL1}|g" \
#     -e "s|\${RAW_JDBC_URL2}|${RAW_JDBC_URL2}|g" \
#     -e "s|\${RAW_DB_USER}|${RAW_DB_USER}|g" \
#     -e "s|\${RAW_DB_PASSWORD}|${RAW_DB_PASSWORD}|g" \
#     /etc/trino/template/mssql_mes_sft_low.properties.template > /etc/trino/catalog/mssql_mes_sft_low.properties

# sed -e "s|\${HIVE_METASTORE_URI}|${HIVE_METASTORE_URI}|g" \
#     -e "s|\${MINIO_ENDPOINT}|${MINIO_ENDPOINT}|g" \
#     -e "s|\${MINIO_ACCESS_KEY}|${MINIO_ACCESS_KEY}|g" \
#     -e "s|\${MINIO_SECRET_KEY}|${MINIO_SECRET_KEY}|g" \
#     /etc/trino/template/delta.properties.template > /etc/trino/catalog/delta.properties

sed -e "s|\${ICE_DB_NAME}|${ICE_DB_NAME}|g" \
    -e "s|\${ICE_JDBC_URL}|${ICE_JDBC_URL}|g" \
    -e "s|\${ICE_DB_USER}|${ICE_DB_USER}|g" \
    -e "s|\${ICE_DB_PASSWORD}|${ICE_DB_PASSWORD}|g" \
    -e "s|\${ICEBERG_DIR}|${ICEBERG_DIR}|g" \
    -e "s|\${MINIO_ENDPOINT}|${MINIO_ENDPOINT}|g" \
    -e "s|\${MINIO_ACCESS_KEY}|${MINIO_ACCESS_KEY}|g" \
    -e "s|\${MINIO_SECRET_KEY}|${MINIO_SECRET_KEY}|g" \
    /etc/trino/template/iceberg.properties.template > /etc/trino/catalog/iceberg.properties

echo "Configuration file generated successfully!"
#echo "[INFO] Initializing DuckDB..."
#/opt/duckdb/duckdb /opt/duckdb/tino.db < /opt/duckdb/load.sql

# Start Trino server
echo "[INFO] Starting Trino..."
exec /usr/lib/trino/bin/run-trino
