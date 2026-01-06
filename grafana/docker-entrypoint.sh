#!/bin/bash
set -e

# List of required environment variables
required_vars=("SERVER_NAME" "POSTGRES_HOST" "POSTGRES_PORT" "GRAFANA_DB_NAME" "GRAFANA_DB_USER" "GRAFANA_DB_PASSWORD" "KEYCLOAK_CLIENT_SECRET")

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
sed -e "s|\${SERVER_NAME}|${SERVER_NAME}|g" \
    -e "s|\${POSTGRES_HOST}|${POSTGRES_HOST}|g" \
    -e "s|\${POSTGRES_PORT}|${POSTGRES_PORT}|g" \
    -e "s|\${GRAFANA_DB_NAME}|${GRAFANA_DB_NAME}|g" \
    -e "s|\${GRAFANA_DB_USER}|${GRAFANA_DB_USER}|g" \
    -e "s|\${GRAFANA_DB_PASSWORD}|${GRAFANA_DB_PASSWORD}|g" \
    -e "s|\${KEYCLOAK_CLIENT_SECRET}|${KEYCLOAK_CLIENT_SECRET}|g" \
    /etc/grafana/grafana.ini.template > /etc/grafana/grafana.ini
echo "Configuration file generated successfully!"

# Start Grafana server
exec /run.sh

