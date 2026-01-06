# Makefile to manage Dutchboy docker images

# VARIABLES
# -----------------------------------------------------------------------------
SPARK_APP_NAME=create_schema.py
DATA_ROOT=./volumes

# 도커 네트워크 생성
# -----------------------------------------------------------------------------
.PHONY: create-network
create-network:
	@docker network inspect data-network > /dev/null 2>&1 || docker network create --driver bridge data-network
	@echo "Network data-network created"

# 전체 서비스 빌드(prod : minio postgres spark trino airflow sqlmesh mlflow grafana)
# -----------------------------------------------------------------------------
.PHONY: compose-all-build
compose-all-build:
	@mkdir -p ${DATA_ROOT}/minio
	@mkdir -p ${DATA_ROOT}/minio/minio1-1 ${DATA_ROOT}/minio/minio1-2
	@mkdir -p ${DATA_ROOT}/minio/minio2-1 ${DATA_ROOT}/minio/minio2-2
	@mkdir -p ${DATA_ROOT}/minio/minio3-1 ${DATA_ROOT}/minio/minio3-2
	@mkdir -p ${DATA_ROOT}/minio/minio4-1 ${DATA_ROOT}/minio/minio4-2
	@chown -R aibiz:aibiz ${DATA_ROOT}/minio
	@docker build ./minio --no-cache --tag aibiz_minio:2024-12-13T22-19-12Z
	@docker build ./nginx --no-cache --tag aibiz_nginx:1.19.2-alpine

# 전체 서비스 실행(prod)
# -----------------------------------------------------------------------------
.PHONY: compose-all-up
compose-all-up: create-network
	@docker compose --profile prod --env-file .env up -d

# 서비스 실행(minio)
# -----------------------------------------------------------------------------
.PHONY: compose-minio-up
compose-minio-up: create-network
	@docker compose --profile minio up -d

# MinIO 백업
.PHONY: compose-minio-backup
compose-minio-backup: compose-minio-down
	@sudo systemctl start minio
	@mc alias set myminio http://localhost:7078 aibiz aibiz12#$
	@mkdir -p ${DATA_ROOT}/backup/minio_backup
	@mc mirror myminio ${DATA_ROOT}/backup/minio_backup
	@sudo systemctl stop minio

# MinIO 복원 (overwrite)
.PHONY: compose-minio-restore
compose-minio-restore: compose-minio-up
	@mc alias set myminio http://localhost:7078 aibiz aibiz12#$
	@mc mirror ${DATA_ROOT}/backup/minio_backup myminio --overwrite

# 서비스 실행(nginx)
# -----------------------------------------------------------------------------
.PHONY: compose-nginx-up
compose-nginx-up: create-network
	@docker compose --profile nginx up -d

# 전체 서비스 종료(prod : minio trino spark airflow)
# -----------------------------------------------------------------------------
.PHONY: compose-all-down
compose-all-down:
	@docker compose --profile prod down
	@docker network rm data-network
	@echo "Network data-network removed"

# 서비스 종료(minio)
# -----------------------------------------------------------------------------
.PHONY: compose-minio-down
compose-minio-down:
	@docker compose --profile minio down

# 서비스 종료(nginx)
# -----------------------------------------------------------------------------
.PHONY: compose-nginx-down
compose-nginx-down:
	@docker compose --profile nginx down

# 전체 이미지 삭제
# -----------------------------------------------------------------------------
.PHONY: clean-all
clean-all: clean clean-dutchboy
	@docker rmi $(docker images -q)
	@docker system prune -f

# 정기적으로 아래 명령실행 필요(사용하지 않는 이미지, 볼룸만 삭제)
# docker system prune -a

# 도움말
# -----------------------------------------------------------------------------
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  create-network    		Create docker network if not exists"
	@echo "  compose-all-build 		Build all docker images"
	@echo "  compose-all-up    		Compose up all services"
	@echo "  compose-service-up     Compose up a service"
	@echo "  compose-all-down  		Compose down all services then remove network"
	@echo "  compose-service-down  	Compose down a service"
	@echo "  clean-all        		Clean all"
	@echo "  help              		Show this help message"
	@echo "  valid service list     minio, nginx
	@echo ""