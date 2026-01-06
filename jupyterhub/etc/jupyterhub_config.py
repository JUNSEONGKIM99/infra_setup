import os
import subprocess
from jupyterhub.spawner import SimpleLocalProcessSpawner
from oauthenticator.generic import GenericOAuthenticator

# JupyterHub 설정 객체 가져오기
c = get_config()

# 로그 레벨 설정
c.Application.log_level = "INFO"

# JupyterHub 서버 바인딩 주소 및 포트 설정
c.JupyterHub.bind_url = "http://0.0.0.0:8000"
c.JupyterHub.hub_bind_url = "http://localhost:8081"
c.JupyterHub.hub_connect_url = c.JupyterHub.hub_bind_url

# Keycloak 서버 도메인 주소
server_name = os.getenv("SERVER_NAME", "rnd6.ai-biz.net")
keycloak_client_secret = os.getenv("KEYCLOAK_CLIENT_SECRET", "SD0lUCe4vKB8zdGDObqGjDxFqjYVwWyw")

# 사용자별 Jupyter Notebook 서버 관리
class CustomSpawner(SimpleLocalProcessSpawner):
    # 원하는 한도 (bytes)
    per_user_mem = 36 * 1024 ** 3        # 36 GiB
    per_user_cpu = 16 * 60 * 60          # 16 CPU 시간

    def start(self):
        # 리미트
        self.resource_limits = {
            "memory": self.per_user_mem,     # RLIMIT_AS
            "cpu":    self.per_user_cpu,     # RLIMIT_CPU (초)
        }
        
        # 사용자 홈 디렉토리 설정(./volumes/jupyterhub/home에 저장됨)
        user_home = f"/home/{self.user.name}"
        user_venv = f"{user_home}/venv"
        base_venv = "/usr/local/venv/base"
        ds_venv = "/usr/local/venv/dutchboy"
        user_notebooks = f"{user_home}/notebooks"
        base_user = "aibiz"

        # 1. 사용자 홈 디렉토리 생성
        if not os.path.exists(user_home):
            self.log.info(f"Creating home directory for user {self.user.name} at {user_home}")
            os.makedirs(user_home, exist_ok=True)
            subprocess.run(["chown", "-R", f"{base_user}:{base_user}", user_home])

        # 2. 사용자별 가상환경 생성
        if not os.path.exists(f"{user_venv}/bin/python"):
            self.log.info(f"Creating virtual environment for user {self.user.name} at {user_venv}")
            subprocess.run(["python3", "-m", "venv", user_venv, "--without-pip"], check=True)
            subprocess.run(f"curl -s https://bootstrap.pypa.io/get-pip.py | /home/{self.user.name}/venv/bin/python", shell=True, check=True)
            subprocess.run([f"{user_venv}/bin/pip", "install", "jupyterhub", "notebook", "jupyterlab", "ipykernel", "jupyter-server-proxy"], check=True)
            subprocess.run(["chown", "-R", f"{base_user}:{base_user}", user_venv])

        # 3. 사용자 notebooks 디렉토리 생성
        if not os.path.exists(user_notebooks):
            self.log.info(f"Creating notebooks directory for user {self.user.name} at {user_notebooks}")
            os.makedirs(user_notebooks, exist_ok=True)
            subprocess.run(["chown", "-R", f"{base_user}:{base_user}", user_notebooks])

        # 4. 사용자 전용 jupyter_server_config.py 생성
        subprocess.run([f"{user_venv}/bin/jupyter", "server", "extension", "enable", "jupyter_server_proxy"], check=True)
        notebook_config_path = f"{user_venv}/etc/jupyter/jupyter_notebook_config.py"
        if not os.path.exists(notebook_config_path):
            os.makedirs(os.path.dirname(notebook_config_path), exist_ok=True)
            with open(notebook_config_path, 'w') as f:
                f.write("""
c.ServerProxy.servers = {
    'vscode': {
        'command': ['/opt/code-server/bin/code-server', '--auth=none', '--port={port}'],
        'timeout': 60,
        'launcher_entry': {
            'title': 'VS Code',
            'icon_path': '/etc/jupyterhub/vs_code_icon.svg'
        }
    }
}
""")

        # 5. 사용자별 환경변수 설정
        self.log.info(f"Setting environments for user {self.user.name} at {user_notebooks}")
        self.environment.update({
            'HOME': f"{user_home}",
            'USER': f"{self.user.name}",
            'LOGNAME': f"{self.user.name}",
            'JUPYTER_PATH': f"{user_venv}/share/jupyter:{base_venv}/share/jupyter",
            'PYTHONPATH': f"{user_venv}/lib/python3.12/site-packages:{base_venv}/lib/python3.12/site-packages:{ds_venv}/lib/python3.12/site-packages:/etc/ds_mlflow:/etc/dutchboy_system",
            'VIRTUAL_ENV': f"{user_venv}",
            'PATH': f"{user_venv}/bin:{base_venv}/bin:" + os.environ['PATH'],
        })

        # 6. 사용자별 커맨드 설정
        self.log.info(f"Starting for user {self.user.name} at {user_notebooks}")
        self.cmd = [f"{user_venv}/bin/jupyterhub-singleuser"]
        return super().start()

# Spawner 클래스 지정
c.JupyterHub.spawner_class = CustomSpawner

# 기본 Jupyter Lab 인터페이스 설정
c.Spawner.notebook_dir = "/home/{username}/notebooks"   # 탬플릿 변수라서 f를 쓰지 않음
c.Spawner.default_url = "/lab"
#c.Spawner.args = ["--ServerApp.disable_check_xsrf=True"] # 서버 세션을 명확히 초기화

# 쿠키 및 DB 파일 설정
c.JupyterHub.cookie_secret_file = "/etc/jupyterhub/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////etc/jupyterhub/jupyterhub.sqlite"
c.ConfigurableHTTPProxy.pid_file = "/etc/jupyterhub/jupyterhub-proxy.pid"

# Jupyter Lab을 기본 인터페이스로 제공
c.LocalProcessSpawner.environment = {
    'JUPYTERHUB_SINGLEUSER_APP': 'jupyter_server.serverapp.ServerApp',
}

# 사용자 환경변수 유지
c.Spawner.env_keep = [
    'PATH', 'LD_LIBRARY_PATH', 'JAVA_HOME', 'SPARK_HOME',
    'AIRFLOW_HOME', 'AIRFLOW__CORE__EXECUTOR', 'AIRFLOW__DATABASE__SQL_ALCHEMY_CONN', 'AIRFLOW__DATABASE__SQL_ALCHEMY_CONN',
    'AIRFLOW__CELERY__RESULT_BACKEND', 'AIRFLOW__CELERY__BROKER_URL',
    'MLFLOW_TRACKING_URI', 'MLFLOW_S3_ENDPOINT_URL',
    'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_S3_ENDPOINT_URL',
    'SERVER_NAME','KEYCLOAK_CLIENT_SECRET'
]

# 관리자 사용자 설정
c.Authenticator.admin_users = {'aibiz'}

# 시스템 사용자 사용하지 않음
#c.LocalAuthenticator.create_system_users = False

# Keycloak SSO 설정
c.JupyterHub.authenticator_class = GenericOAuthenticator

# Keycloak OAuth2 설정
c.GenericOAuthenticator.client_id = 'jupyterhub'
c.GenericOAuthenticator.client_secret = keycloak_client_secret
c.GenericOAuthenticator.oauth_callback_url = f"https://jupyterhub.{server_name}/hub/oauth_callback"

# Keycloak Authorization URLs
c.GenericOAuthenticator.authorize_url = f"https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/auth"
c.GenericOAuthenticator.token_url = f"https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/token"
c.GenericOAuthenticator.userdata_url = f"https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/userinfo"
c.GenericOAuthenticator.logout_redirect_url = f"https://keycloak.{server_name}/realms/dutchboy/protocol/openid-connect/logout?redirect_uri=https://jupyterhub.{server_name}/hub/"
c.GenericOAuthenticator.userdata_params = {'state': 'state'}
c.GenericOAuthenticator.scope = ['openid', 'profile', 'email']

# 사용자 인증 속성
c.GenericOAuthenticator.username_claim = 'preferred_username'

# 관리자 및 허용된 사용자 설정
c.Authenticator.admin_users = {'admin'}
#c.Authenticator.any_allow_config = True
c.Authenticator.allowed_users = {'aibiz','bmkim','dmkim','gugo','iwhwang','jhpark','jgkim','jmum','jskim','jslee','miseo','mskim','shoh','silee','sokim','yjjang', 'shchoi', 'thnoh', 'hjkwon', 'hsjung', 'hyjo', 'jhkim2', 'gdsong', 'mhko', 'nhchoi', 'stpark', 'jwseo'}

# 세션 타임아웃 및 스폰 타임아웃 설정
c.Spawner.start_timeout = 60
c.Spawner.http_timeout = 30
