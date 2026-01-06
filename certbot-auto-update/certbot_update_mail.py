#!/bin/bash

# ==================================================
# SSL certificate renewal Email Sending
# Author  : gdsong
# History :
#   - 최초 구성
#     작성자(gdsong)에게만 전달이 되게끔 설정
#     => 추 후, 다른 팀원에게도 전달 필요
#
#   - 개선 사항
#     인자를 받아서 갱신 실패 시에도 메일 발송 기능 추가
#
# Note    :
#   - 사용 방법
#     해당 파일을 python certbot_update_mail.py
#     (자동화 적용 시, 실행 불필요)
# ==================================================

import sys
import socket
import smtplib
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# ==================================================
# 1.VARIABLES & FUNCTIONS: 1.변수 및 함수 선언
# ==================================================
hostname = socket.gethostname() # 서버 호스트명
update_status = sys.argv[1] if len(sys.argv) > 1 else "OK" # 인증서 업데이트 상태 정의, default는 ok 상태
update_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S") # 인증서 업데이트 실행 일시
expired_time = (datetime.strptime(update_time, "%Y-%m-%d %H:%M:%S") + timedelta(days=80)).strftime("%Y-%m-%d %H:%M:%S") # 인증서 만료 일시
mail_first_line = "" # 메일의 첫번째 줄

# 메일 내용 작성 함수
def make_body(f_line, hname, u_status, u_time, e_time):
    return (
        f"{f_line}\n\n"
        f"갱신 서버: {hname}\n"
        f"갱신 상태: {u_status}\n"
        f"갱신 일시: {u_time}\n"
        f"만료 일시: {e_time}\n\n"
        f"감사합니다.\n"
        f"Certbot 드림"
    )

# ==================================================
# 2.SERVER: 2.메일 서버 설정
# ==================================================
smtp_server = "smtp.gmail.com"
smtp_port = 587

sender = "gdsong@ai-biz.net" # 발신자 지정
password = "jksl ldis zpux sndx" # 발신자 메일의 "앱" 비밓번호
receiver = "gdsong@ai-biz.net" # 수신자 지정
#receivers = [ "gdsong@ai-biz.net", "rhkim@ai-biz.net" ] # 수신자 다수 지정


# ==================================================
# 3.CONTENTS: 3.메일 내용 구성
# ==================================================
print("전달받은 갱신 작업 상태: ", update_status)

if update_status == "OK":
    msg = MIMEMultipart()
    msg["From"] = sender
    msg["To"] = receiver
    msg["Subject"] = f"{hostname} - Certbot Update Complete" # 갱신 성공 메일의 제목
    mail_first_line = "SSL 인증서 갱신이 완료되었습니다."
    body = make_body(mail_first_line, hostname, update_status, update_time, expired_time) # 갱신 성공 메일의 내용
    msg.attach(MIMEText(body, "plain"))
elif update_status == "ERR":
    msg = MIMEMultipart()
    msg["From"] = sender
    msg["To"] = receiver
    msg["Subject"] = f"{hostname} - Certbot Update Failed" # 갱신 실패 메일의 제목
    mail_first_line = "SSL 인증서 갱신이 실패하였습니다."
    body = make_body(mail_first_line, hostname, update_status, update_time, "-") # 갱신 실패 메일의 내용
    msg.attach(MIMEText(body, "plain"))
else:
    msg = MIMEMultipart()
    msg["From"] = sender
    msg["To"] = receiver
    msg["Subject"] = f"{hostname} - Certbot Update Unknown Error" # 갱신 오류 메일의 제목
    mail_first_line = "SSL 인증서 갱신 중, 알 수 없는 오류가 발생하였습니다."
    body = make_body(mail_first_line, hostname, update_status, update_time, "-") # 갱신 오류 메일의 내용
    msg.attach(MIMEText(body, "plain"))

# ==================================================
# 4.SENDING: 4.메일 발송
# ==================================================
server = smtplib.SMTP(smtp_server, smtp_port)
server.starttls()
server.login(sender, password)
server.send_message(msg)
server.quit()

print(f"{hostname} - EMAIL Sending Complete: {update_status}")
