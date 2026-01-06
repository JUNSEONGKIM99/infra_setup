#!/bin/bash

# ==================================================
# SSL certificate renewal(with certbot)
# Author  : gdsong
# History :
#   - 피드백 사항
#     원본 파일을 수정하는 방식은 안 좋은 코드 => 독립적인 실행으로 변경
#     들여쓰기 적용
#     변수에 Default값을 지정해서 사용
#     => 적용 완료
#
#   - 최대한 넓은 범위의 경우의 수를 고려하여 파일 구성
#
#   - 파일 생성 확인 로직 수정
#     파일의 개수로 확인 시, 최대 24개만 생성되어 이후는 확인이 불가능
#     파일의 개수가 아닌 파일의 리스트를 저장해서 생성 여부 확인
#
#   - 인증서 재발급 진행 시, 메일 발송
#     파이썬으로 구성
#
#   - 파일의 위치를 ~/setup/에서 ~/setup/certbot-auto-update/로 이동
#     필요한 파일들을 한 번에 관리하기 위한 조치
# 
# Note    :
#   - 필요 파일
#     Makefile_certbot, docker-compose_certbot.yml, curr, prev, certbot_update_mail.py
#
#   - 사용 방법
#     해당 파일을 /home/aibiz/setup 디렉토리로 이동
#     명령어 실행 sudo ./certbot-update.sh
#     (자동화 적용 시, 실행 불필요)
# ==================================================


# ==================================================
# 1.VARIABLES: 1.변수 선언
# ==================================================
SERVER_NAME="$(hostname).ai-biz.net" # 인증서를 업데이트할 서버 지정
CERTBOT_PATH="/data/volumes/certbot/conf/archive/$SERVER_NAME" # 키파일이 생성될 경로 지정
CERTBOT_DIFF_PATH="/home/aibiz/setup/certbot-auto-update" # 파일 리스트 변경 확인 경로 지정
MAXIUM_WAIT=10 # 인증서 파일 생성 최대 대기 횟수
COUNT=0 # 인증서 파일 대기 카운트

# 도메인명 디렉토리가 없으면 생성
if [ ! -d "$CERTBOT_PATH" ]; then
  echo "[$(date '+%F %T')] 도메인명 $SERVER_NAME 폴더 생성"
  mkdir -p $CERTBOT_PATH
fi

PREV_FILE_LIST=$CERTBOT_DIFF_PATH/prev # 기존 파일 리스트
CURR_FILE_LIST=$CERTBOT_DIFF_PATH/curr # 최신 파일 리스트
ls $CERTBOT_PATH > $PREV_FILE_LIST
ls $CERTBOT_PATH > $CURR_FILE_LIST

# 정상 출력 확인용
echo "[$(date '+%F %T')] 전체 도메인 출력: $CERTBOT_PATH"
echo "[$(date '+%F %T')] 기존 폴더 파일 목록: $PREV_FILE_LIST"

# ==================================================
# 2.Certbot container execute: 2.Certbot 컨테이너 실행
# ==================================================
cd $CERTBOT_DIFF_PATH
make -f Makefile_certbot renewal_certbot-up # certbot 컨테이너 실행
echo "[$(date '+%F %T')]########### Certbot 컨테이너 실행 ###########"

while diff $PREV_FILE_LIST $CURR_FILE_LIST > /dev/null 2>&1; do
  if [ "$COUNT" -ge "$MAXIUM_WAIT" ]; then
    echo "[$(date '+%F %T')] ########### 인증서 파일 생성 실패 ###########"
    FAIL_FLAG=1
    break
  fi

  sudo chown -R aibiz:aibiz /home/aibiz/setup/volumes/certbot
  ls $CERTBOT_PATH > $CURR_FILE_LIST
  echo "[$(date '+%F %T')] 인증서 파일 생성 대기 중($COUNT/$MAXIUM_WAIT)"
  sleep 5
  COUNT=$((COUNT + 1))
done

if [ "${FAIL_FLAG:-0}" != 1 ]; then
  echo "[$(date '+%F %T')] ########### 파일 생성 완료 ###########"
fi

make -f Makefile_certbot renewal_certbot-down # certbot 컨테이너 종료
echo "[$(date '+%F %T')]########### Certbot 컨테이너 종료 ###########"

# ==================================================
# 3.Change owner: 3.키파일 소유자 변경
# ==================================================
echo "[$(date '+%F %T')]########### 키파일 소유자 변경 ###########"
# conf 하위 디렉토리 소유자 및 그룹 변경
sudo chown -R aibiz:aibiz /home/aibiz/setup/volumes/certbot

# ==================================================
# 4.Nginx container execute: 4.Nginx 컨테이너 실행
# ==================================================
cd $CERTBOT_DIFF_PATH
echo "[$(date '+%F %T')] nginx 컨테이너 종료"
make -f Makefile_certbot renewal_nginx-down
echo "[$(date '+%F %T')] nginx 컨테이너 실행"
make -f Makefile_certbot renewal_nginx-up

if [ "$FAIL_FLAG" = 1 ]; then
  python3 ./certbot_update_mail.py err
  echo "[$(date '+%F %T')] 오류 메일 발송 완료"
else
  python3 ./certbot_update_mail.py
  echo "[$(date '+%F %T')] 메일 발송 완료"
fi