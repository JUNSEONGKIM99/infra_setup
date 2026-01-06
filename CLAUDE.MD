# Project Overview

This is an infrastructure setup repository for managing a comprehensive data platform using Docker Compose. The project includes various services for data engineering, analytics, monitoring, and development tools.

## Project Structure

- **Root directory**: `/Users/jskim/work/infra_setup`
- **Main orchestration**: `docker-compose.yml` and `docker-compose-gpu.yml`
- **Build automation**: `Makefile` with extensive service management commands
- **Configuration**: Service-specific directories with configs and volumes

## Key Services & Components

### Authentication & Identity
- **Keycloak**: SSO with OIDC support integrated with OpenLDAP
- **OpenLDAP**: LDAP directory service
- **phpLDAPadmin**: Web interface for LDAP management

### Data Platform
- **Airflow**: Workflow orchestration (CeleryExecutor with Redis)
- **Spark**: Distributed data processing
- **Trino**: Distributed SQL query engine
- **Kafka**: Event streaming platform
- **dbt**: Data transformation tool
- **Hive Metastore (HMS)**: Metadata management

### Storage & Databases
- **MinIO**: S3-compatible object storage
- **PostgreSQL**: Relational database
- **Redis**: In-memory data store

### Analytics & BI
- **Lightdash**: BI and analytics platform
- **OpenMetadata**: Data catalog and metadata management
- **SQLMesh**: SQL-based data transformation

### ML & AI
- **MLflow**: Machine learning lifecycle management
- **JupyterHub**: Multi-user Jupyter notebook environment
- **vLLM (vllm-qwen32b)**: High-performance LLM inference server with OpenAI-compatible API
  - Based on vLLM v0.13.0 with PyTorch 2.9.0, CUDA 12.9
  - Optimized for H100 GPUs with torchao and fbgemm-gpu-genai
  - Supports AWQ quantization for efficient inference
  - Model: Qwen/Qwen2.5-32B-Instruct-AWQ
  - OpenAI-compatible endpoints at port 8093
  - Configurable GPU memory utilization, max model length, KV cache offloading
  - Custom entrypoint script for flexible configuration (vll-sub1/entrypoint.sh)
- **Open-WebUI**: Modern web interface for interacting with LLMs
  - Container name: open-webui
  - Web UI accessible at port 8094
  - Integrated with vllm-qwen32b service via OpenAI-compatible API
  - URL: https://llm.rnd6.ai-biz.net
  - Ollama API disabled (using vLLM backend instead)

### Monitoring & Observability
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Metrics visualization and dashboards
- **Node Exporter**: Hardware and OS metrics
- **DCGM Exporter**: GPU metrics for NVIDIA devices

### Development Tools
- **GitLab**: Source code management and CI/CD
- **GitLab Runner**: CI/CD pipeline execution
- **Nexus**: Artifact repository
- **SonarQube**: Code quality and security analysis
- **Portainer**: Docker container management UI

### Web Services
- **Nginx**: Reverse proxy with SSL/TLS termination
- **Certbot**: SSL certificate management (Let's Encrypt)
- **FastAPI**: API framework
- **Spring Boot**: Java application framework
- **Tomcat**: Java servlet container

### File Services
- **Samba**: File sharing
- **FTP**: File transfer service
- **Draw.io**: Diagram creation tool

## Network Configuration

- **Network name**: `data-network`
- **Extra hosts**: Services are configured to resolve `keycloak.${SERVER_NAME}` for SSO integration
- **Reverse proxy**: Nginx handles SSL termination and routing to backend services

## Environment Variables

The project uses `.env` file for configuration. Key variables include:
- `SERVER_NAME`: Server domain name
- `SERVER_IP`: Server IP address
- `AIRFLOW_DB_URL`: Airflow database connection string
- `KEYCLOAK_CLIENT_SECRET`: Keycloak client secret for OIDC

## Service Profiles

Services are organized using Docker Compose profiles:
- `prod`: Production services
- `rnd6`: R&D environment services
- Service-specific profiles (e.g., `airflow`, `nginx`, `gitlab`, `vllm`, `open-webui`)

## Volume Management

Persistent data is stored in `./volumes/` directory with service-specific subdirectories:
- `./volumes/airflow/` - Airflow DAGs, logs, plugins
- `./volumes/certbot/` - SSL certificates
- Service-specific volumes for PostgreSQL, MinIO, Grafana, etc.

Host volumes (outside Docker Compose managed volumes):
- `/data/volumes/vllm-data/hf-cache` - Hugging Face model cache for vLLM
- `/data/volumes/vllm-data/lmcache` - LMCache directory for KV cache offloading
- `/data/semes` - Production data (read-only mount)
- `/data/zipfile` - Shared data for DE team

## Build System

The `Makefile` provides commands for:
- Starting/stopping individual services or groups
- Building custom Docker images
- Managing service dependencies
- Common operations (logs, restart, cleanup)

## Technology Stack

- **Container orchestration**: Docker, Docker Compose
- **Programming**: Python, Java, Scala
- **Data processing**: Spark, Trino, Airflow
- **Databases**: PostgreSQL, Redis
- **Monitoring**: Prometheus, Grafana
- **Authentication**: Keycloak, OpenLDAP

## Important Notes

1. **MinIO Keycloak Integration**: MinIO may not recognize Keycloak on first startup even with `depends_on`. Restart MinIO after Keycloak is fully initialized.

2. **Airflow Configuration**: Uses CeleryExecutor with Redis as message broker and PostgreSQL as metadata database.

3. **SSL/TLS**: Managed through Certbot with automatic renewal. Nginx serves as SSL termination point.

4. **Shared Python Environment**: Custom Python environments are mounted read-only from host:
   - `/usr/local/venv/base` - Base Python environment
   - `/usr/local/venv/dutchboy` - Dutchboy-specific packages
   - `/usr/local/venv/pyceberg` - PyIceberg environment

5. **Spark Integration**: Airflow containers have Spark binaries and configs mounted for running Spark jobs.

6. **Data Access**: Production data mounted from `/data/` directory on host.

7. **vLLM Configuration**:
   - Custom Docker image built from `vll-sub1/dockerfile` based on vLLM v0.13.0
   - Requires NVIDIA GPU with CUDA 12.9 support (optimized for H100)
   - Uses IPC host mode with 64GB shared memory for optimal performance
   - Model cache stored in `/data/volumes/vllm-data/`
   - Entrypoint script (`vll-sub1/entrypoint.sh`) provides flexible configuration via environment variables:
     - MODEL, SERVED_MODEL_NAME, GPU_MEMORY_UTILIZATION
     - QUANTIZATION (AWQ), MAX_MODEL_LEN
     - KV_OFFLOADING_BACKEND (lmcache support)
     - CPU_OFFLOAD_GB, SWAP_SPACE for memory management
   - Backup scripts available in `vll-sub1/backups/`

8. **Open-WebUI Integration**:
   - Connects to vLLM backend via OpenAI-compatible API
   - Accessible through Nginx reverse proxy at https://llm.rnd6.ai-biz.net
   - No persistent volume configured (data stored in container)
   - Environment variables:
     - `OPENAI_API_BASE_URL`: Points to vllm-qwen32b service
     - `ENABLE_OLLAMA_API`: Disabled (using vLLM instead)
     - `TRUST_PROXY`: Enabled for reverse proxy compatibility

## Git Configuration

- **Repository**: GitLab instance at `gitlab.ai-biz.net`
- **User**: jslee
- **Main branch**: `main`
- **Recent commits**: Focus on configuration cleanup and security (removing SSH keys, updating .gitignore)

## When Making Changes

1. **Service configuration**: Check the respective service directory under root
2. **Docker Compose changes**: Update `docker-compose.yml` and rebuild if necessary
3. **Build automation**: Update `Makefile` for new services or commands
4. **Secrets**: Never commit sensitive data; use `.env` file (already in .gitignore)
5. **SSL certificates**: Managed automatically by Certbot, stored in `./volumes/certbot/`

## Common Commands

Check the `Makefile` for available commands. Typical operations:
- Start services: `make <service-name>`
- View logs: `docker-compose logs -f <service-name>`
- Restart: `docker-compose restart <service-name>`
- Stop all: `docker-compose down`
