# 데모용 깨끗한 코드 — 실제 값 없이 빈 자리(placeholder)로만 작성된 예
# config-secret 의 check-no-hardcoded-values 게이트가 이걸 검사해 통과한다.
import os


def build_url():
    host = os.environ["MESSENGER_HOST"]      # 빈 자리 — 내부망에서 주입
    path = "${MESSENGER_PATH}"                # 빈 자리
    return f"{host}{path}"


def send_memo(recipient, title, body):
    srv = os.environ["MESSENGER_SRV_CODE"]    # 빈 자리 — 비밀 저장소에서 주입
    payload = {
        "SRV_CODE": srv,
        "RECIPIENT": recipient,
        "TITLE": title,
        "BODY": body,
    }
    return post(build_url(), payload)
