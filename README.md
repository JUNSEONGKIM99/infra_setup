# Infrastructure Setup

Docker Compose 기반의 통합 데이터 플랫폼 인프라 구성 프로젝트입니다. 데이터 엔지니어링, 분석, ML/AI, 모니터링, 개발 도구를 포함한 종합적인 서비스 스택을 제공합니다.

## 주요 특징

- **완전한 데이터 플랫폼**: Airflow, Spark, Trino, Kafka를 활용한 데이터 파이프라인
- **ML/AI 인프라**: MLflow, JupyterHub, vLLM 기반 LLM 추론 서버
- **통합 인증**: Keycloak + OpenLDAP 기반 SSO 및 OIDC 지원
- **모니터링 및 관찰성**: Prometheus, Grafana, GPU 메트릭 수집
- **개발 도구**: GitLab, Nexus, SonarQube, Portainer

## 시스템 요구사항

- Docker 및 Docker Compose
- NVIDIA GPU (vLLM 서비스 사용 시, H100 최적화)
- CUDA 12.9 이상 (GPU 서비스)
- 충분한 디스크 공간 (모델 캐시 및 데이터 볼륨)

## 빠른 시작

### 1. 네트워크 생성

```bash
docker network create --driver bridge data-network
```

### 2. 환경 변수 설정

`.env` 파일을 생성하고 다음 변수들을 설정합니다:

```bash
SERVER_NAME=your-domain.com
SERVER_IP=your-server-ip
AIRFLOW_DB_URL=airflow:airflow@postgres:5432/airflow
KEYCLOAK_CLIENT_SECRET=your-keycloak-secret
```

### 3. 서비스 시작

Makefile을 사용하여 서비스를 시작합니다:

```bash
# 전체 프로덕션 스택 시작
make prod

# 개별 서비스 시작
make airflow
make nginx
make vllm
```

또는 Docker Compose를 직접 사용:

```bash
# 프로파일 기반 시작
docker-compose --profile prod up -d

# 특정 서비스 시작
docker-compose up -d nginx airflow-webserver
```

## 주요 서비스

### 데이터 플랫폼

- **Airflow** (포트: 8080): 워크플로우 오케스트레이션
  - CeleryExecutor 사용
  - Redis 메시지 브로커
  - PostgreSQL 메타데이터 DB

- **Spark**: 분산 데이터 처리
- **Trino**: 분산 SQL 쿼리 엔진
- **Kafka**: 이벤트 스트리밍
- **Hive Metastore**: 메타데이터 관리

### ML/AI

- **MLflow**: ML 생명주기 관리
- **JupyterHub**: 멀티 유저 Jupyter 노트북
- **vLLM (vllm-qwen32b)** (포트: 8093):
  - OpenAI 호환 API를 제공하는 고성능 LLM 추론 서버
  - 모델: Qwen/Qwen2.5-32B-Instruct-AWQ
  - H100 GPU 최적화 (torchao, fbgemm-gpu-genai)
  - AWQ 양자화 지원

- **Open-WebUI** (포트: 8094, https://llm.rnd6.ai-biz.net):
  - LLM과 상호작용하는 모던 웹 인터페이스
  - vLLM 백엔드와 통합

### 스토리지 및 데이터베이스

- **MinIO**: S3 호환 객체 스토리지
- **PostgreSQL**: 관계형 데이터베이스
- **Redis**: 인메모리 데이터 스토어

### 인증 및 보안

- **Keycloak**: SSO 및 OIDC 제공자
- **OpenLDAP**: LDAP 디렉토리 서비스
- **phpLDAPadmin**: LDAP 웹 관리 인터페이스
- **Nginx**: SSL/TLS 종단 및 리버스 프록시
- **Certbot**: Let's Encrypt SSL 인증서 자동 관리

### 분석 및 BI

- **Lightdash**: BI 및 분석 플랫폼
- **OpenMetadata**: 데이터 카탈로그 및 메타데이터 관리
- **SQLMesh**: SQL 기반 데이터 변환

### 모니터링

- **Prometheus**: 메트릭 수집 및 알림
- **Grafana**: 메트릭 시각화 및 대시보드
- **Node Exporter**: 하드웨어 및 OS 메트릭
- **DCGM Exporter**: NVIDIA GPU 메트릭

### 개발 도구

- **GitLab**: 소스 코드 관리 및 CI/CD
- **GitLab Runner**: CI/CD 파이프라인 실행
- **Nexus**: 아티팩트 저장소
- **SonarQube**: 코드 품질 및 보안 분석
- **Portainer**: Docker 컨테이너 관리 UI

## 디렉토리 구조

```
.
├── docker-compose.yml          # 메인 Docker Compose 설정
├── docker-compose-gpu.yml      # GPU 서비스 설정
├── Makefile                    # 서비스 관리 자동화
├── .env                        # 환경 변수 (gitignore)
├── volumes/                    # 영속성 데이터 볼륨
│   ├── airflow/
│   ├── certbot/
│   └── ...
├── airflow/                    # Airflow 설정
├── nginx/                      # Nginx 설정
├── vll-sub1/                   # vLLM 커스텀 이미지
│   ├── dockerfile
│   ├── entrypoint.sh
│   └── backups/
├── open-webui/                 # Open-WebUI 커스텀 이미지
└── ...                         # 기타 서비스별 디렉토리
```

## 볼륨 관리

### 로컬 볼륨 (./volumes/)
- `./volumes/airflow/` - DAG, 로그, 플러그인
- `./volumes/certbot/` - SSL 인증서
- 서비스별 볼륨 (PostgreSQL, MinIO, Grafana 등)

### 호스트 볼륨
- `/data/volumes/vllm-data/hf-cache` - Hugging Face 모델 캐시
- `/data/volumes/vllm-data/lmcache` - KV 캐시 오프로딩
- `/data/semes` - 프로덕션 데이터 (읽기 전용)
- `/data/zipfile` - DE 팀 공유 데이터
- `/usr/local/venv/` - 공유 Python 환경 (읽기 전용)

## vLLM 설정 가이드

vLLM 서비스는 커스텀 entrypoint 스크립트를 통해 유연하게 설정할 수 있습니다.

### 주요 환경 변수

```yaml
MODEL: "Qwen/Qwen2.5-32B-Instruct-AWQ"
SERVED_MODEL_NAME: "qwen-32b-24k"
QUANTIZATION: "awq"
GPU_MEMORY_UTILIZATION: "0.90"
MAX_MODEL_LEN: "8192"
```

### 고급 설정

```yaml
# KV 캐시 오프로딩 (LMCache 사용)
KV_OFFLOADING_BACKEND: "lmcache"
KV_OFFLOADING_SIZE: "10"  # GiB

# CPU 메모리 오프로딩
CPU_OFFLOAD_GB: "0"

# 스왑 공간
SWAP_SPACE: "0"  # GiB
```

자세한 설정은 `vll-sub1/entrypoint.sh`를 참고하세요.

## 일반적인 작업

### 로그 확인

```bash
# 특정 서비스 로그
docker-compose logs -f airflow-webserver

# 여러 서비스 로그
docker-compose logs -f nginx vllm-qwen32b open-webui
```

### 서비스 재시작

```bash
# 특정 서비스
docker-compose restart airflow-webserver

# 모든 서비스
docker-compose restart
```

### 서비스 중지

```bash
# 특정 프로파일 서비스만 중지
docker-compose --profile airflow down

# 모든 서비스 중지 (볼륨 유지)
docker-compose down

# 모든 서비스 및 볼륨 삭제
docker-compose down -v
```

### 커스텀 이미지 빌드

```bash
# vLLM 이미지
docker build -t my-vllm:0.9.9 ./vll-sub1/

# Open-WebUI 이미지
docker build -t my-webui ./open-webui/

# Nginx 이미지
docker build -t aibiz_nginx:1.27.3 ./nginx/
```

## 중요 참고사항

### 1. Keycloak 통합
MinIO는 첫 시작 시 `depends_on` 설정에도 불구하고 Keycloak을 인식하지 못할 수 있습니다. Keycloak이 완전히 초기화된 후 MinIO를 재시작하세요.

### 2. SSL 인증서
Certbot을 통해 자동으로 관리됩니다. 인증서는 `./volumes/certbot/conf/`에 저장되며 자동 갱신됩니다.

### 3. GPU 리소스
vLLM 서비스는 모든 GPU를 사용하도록 설정되어 있습니다. 특정 GPU만 사용하려면 `docker-compose.yml`에서 `count: all`을 수정하세요.

### 4. 공유 Python 환경
Airflow 및 기타 서비스는 호스트의 공유 Python 환경을 마운트합니다:
- `/usr/local/venv/base` - 기본 환경
- `/usr/local/venv/dutchboy` - Dutchboy 전용 패키지
- `/usr/local/venv/pyceberg` - PyIceberg 환경

## 문제 해결

### Keycloak 연결 오류
서비스에서 Keycloak 연결 오류가 발생하면 `extra_hosts` 설정을 확인하세요:
```yaml
extra_hosts:
  - "keycloak.${SERVER_NAME}:${SERVER_IP}"
```

### vLLM OOM 에러
GPU 메모리 부족 시 `GPU_MEMORY_UTILIZATION` 값을 낮추거나 `MAX_MODEL_LEN`을 줄이세요.

### SSL 인증서 갱신 실패
Certbot 로그를 확인하고 도메인 DNS 설정 및 포트 80/443 접근성을 확인하세요.

## 기여

이 프로젝트는 AIBIZ Co., Ltd.에서 관리합니다.

## 라이선스

사내 프로젝트

## 연락처

- Author: jslee
- GitLab: https://gitlab.ai-biz.net/jslee/infra_setup
