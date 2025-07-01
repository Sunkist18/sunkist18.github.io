---
title: "Windows 11 PC의 WSL에 Cloudflare Tunnel을 이용해 외부에서 SSH 접속하기"
date: 2025-06-27 12:40:00 +0900
categories: ['Dev-Log', 'On-Premise']
tags: ['WSL', 'SSH', 'Cloudflare', 'Tunnel', 'Windows 11', 'Remote Access']
description: 공인 IP나 포트포워딩 없이 Cloudflare Tunnel로 WSL에 안전하게 원격 접속하는 완벽 가이드 
---

## 문서 개요

이 문서는 공인 IP나 복잡한 공유기 포트포워딩 설정 없이, Windows 11 PC에 설치된 WSL(Windows Subsystem for Linux) 환경에 외부에서 안전하게 SSH로 접속하는 방법을 안내합니다.  
Cloudflare Tunnel을 사용하여 PC가 어떤 네트워크 환경에 있든 상관없이 고유한 도메인 주소로 접속할 수 있게 됩니다.

---

## Cloudflare Tunnel

### 주요 장점

- **공인 IP 불필요**: PC가 유동 IP를 사용하거나 공유기 뒤에 있어도 문제없습니다.
- **포트포워딩 불필요**: 공유기 관리자 페이지에 접속하여 복잡한 설정을 할 필요가 없어 간편하고 안전합니다.
- **강력한 보안**: 모든 통신은 Cloudflare를 통해 암호화되며, 특정 사용자만 접속하도록 접근 제어 정책을 추가할 수 있습니다.
- **고정 주소 사용**: my-wsl.mydomain.com과 같이 기억하기 쉬운 나만의 주소로 언제 어디서든 접속할 수 있습니다.

> Cloudflare Tunnel은 제로 트러스트 아키텍처를 기반으로 하여 기존의 VPN보다 더 안전하고 편리한 원격 접속을 제공합니다.
{: .prompt-info }

---

## 사전 준비물

- **Windows 11 PC**: 내부에 접속하려는 WSL 환경이 설치된 PC
- **WSL2 및 리눅스 배포판**: Ubuntu 등 원하는 리눅스가 설치된 WSL2 환경
- **Cloudflare 계정**: [cloudflare.com](https://cloudflare.com)에서 무료 계정 생성
- **개인 도메인**: Cloudflare에 네임서버가 연결된 도메인이 필요합니다.
- **외부 접속용 PC**: SSH 접속을 시도할 다른 컴퓨터 (노트북 등)

---

## 1단계: WSL에 SSH 서버 설치 및 설정 (접속 대상 PC)

가장 먼저, 외부의 접속을 받아들일 WSL 환경에 SSH 서버를 준비해야 합니다.

### 1.1 SSH 서버 설치

1. **WSL 터미널 실행**: 시작 메뉴에서 wsl 또는 설치한 리눅스 배포판(예: Ubuntu)을 실행합니다.

2. **OpenSSH 서버 설치**: 패키지 목록을 업데이트하고 SSH 서버를 설치합니다.
   ```bash
   sudo apt update && sudo apt install openssh-server
   ```

### 1.2 SSH 설정 수정

외부 접속을 위해 sshd_config 파일을 수정합니다.  
여기서는 가장 간단하고 확실한 **비밀번호 기반 접속**을 설정합니다.

```bash
sudo vim /etc/ssh/sshd_config
```

에디터가 열리면 키보드 방향키로 내려가서 아래 항목을 찾습니다:  
- `#PasswordAuthentication yes` 또는 `PasswordAuthentication no`를 찾아서 아래와 같이 변경합니다.

```bash
PasswordAuthentication yes
```

> **(중요!)** 만약 이전에 다른 방법(예: TrustedUserCAKeys)을 시도한 기록이 있다면, 해당 설정은 #으로 주석 처리하거나 삭제해야 충돌이 없습니다.
{: .prompt-warning }

### 1.3 SSH 서비스 시작

```bash
sudo service ssh start && sudo service ssh status
```

`Active: active (running)` 메시지가 보이면 성공입니다.

### 1.4 WSL 시작 시 SSH 서버 자동 실행 (권장)

WSL은 재시작할 때마다 서비스가 중지됩니다.  
매번 SSH 서버를 켜는 불편함을 없애기 위해 셸 프로필에 자동 시작 명령을 추가합니다.

```bash
vim ~/.profile
```

파일 맨 아래에 다음 내용을 추가하고 저장합니다:

```bash
# SSH 서버 자동 시작
if ! pgrep -x "sshd" > /dev/null
then
    sudo service ssh start
fi
```

---

## 2단계: Cloudflare Tunnel 생성 및 연결 (접속 대상 PC)

이제 Windows PC와 Cloudflare를 연결하는 터널을 만듭니다.

### 2.1 Cloudflare Zero Trust 대시보드 접속

1. Cloudflare 로그인 후 왼쪽 메뉴에서 **Zero Trust**를 클릭합니다.

### 2.2 터널 생성

1. **터널 생성**:
   - Access → Tunnels 메뉴로 이동 후 `Create a tunnel` 버튼을 클릭합니다.
   - 터널 이름을 정하고 (예: my-home-wsl) `Save tunnel`을 클릭합니다.

### 2.3 cloudflared 설치

1. **커넥터(cloudflared) 설치**:
   - Choose your environment 화면에서 OS로 **Windows**, 아키텍처로 **64-bit**를 선택합니다.
   - 오른쪽에 나타나는 **PowerShell 명령어 한 줄을 복사**합니다.
   - **Windows PowerShell을 관리자 권한으로 실행**하고, 복사한 명령어를 붙여넣어 실행합니다.

cloudflared가 Windows 서비스로 자동 설치 및 등록됩니다.

설치가 완료되면 잠시 후 Cloudflare 대시보드의 Connectors 섹션에 초록불과 함께 **HEALTHY** 상태가 표시됩니다.  
`Next` 버튼을 클릭합니다.

### 2.4 Public Hostname 설정

1. **Public Hostname 설정 (주소와 WSL 연결)**:
   - **Subdomain**: 외부에서 사용할 주소를 입력합니다. (예: wsl 또는 my-pc)
   - **Domain**: 준비한 개인 도메인을 선택합니다. (최종 주소는 wsl.yourdomain.com이 됩니다.)
   - **Service**:
     - **Type**: SSH
     - **URL**: localhost:22

> **정보**: localhost:22로 설정하는 이유는 Windows에서 실행되는 cloudflared가 localhost의 22번 포트로 보내는 요청을 WSL2의 22번 포트로 자동으로 전달해주기 때문입니다. 가장 안정적인 방법입니다.
{: .prompt-info }

2. `Save tunnel` 버튼을 눌러 모든 설정을 저장합니다.

---

## 3단계: 외부 PC에서 접속 설정 및 테스트 (접속하는 PC)

이제 준비된 주소로 다른 PC에서 접속을 시도합니다.  
가장 안전하고 권장되는 방법입니다.

### 3.1 cloudflared 설치 (접속하는 PC)

터널을 통과하려면 접속하는 쪽에도 cloudflared가 필요합니다.

**Windows의 경우:**
```powershell
# PowerShell 관리자 권한으로 실행
winget install --id Cloudflare.cloudflared
```

**macOS의 경우:**
```bash
brew install cloudflared
```

**Linux의 경우:**
```bash
# Ubuntu/Debian
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

### 3.2 SSH 설정 파일 수정

SSH 클라이언트가 터널을 통해 접속하도록 설정을 추가합니다.

**설정 파일 위치:**
- **Windows**: `C:\Users\사용자이름\.ssh\config`
- **macOS/Linux**: `~/.ssh/config`

파일이 없다면 새로 만드세요.  
아래 내용을 추가합니다:

```bash
Host wsl.yourdomain.com
  ProxyCommand cloudflared access ssh --hostname %h
```

> **주의**: `wsl.yourdomain.com`을 2단계에서 만든 본인의 주소로 변경하세요.
{: .prompt-warning }

**Windows에서 경로에 공백이 있는 경우:**
```bash
Host wsl.yourdomain.com
  ProxyCommand "C:\Program Files\cloudflared\cloudflared.exe" access ssh --hostname %h
```

### 3.3 SSH 접속 테스트

터미널(PowerShell, iTerm, Terminal 등)을 열고 아래 명령어를 입력합니다:

```bash
ssh username@wsl.yourdomain.com
```

> `username`을 WSL의 실제 사용자명으로, `wsl.yourdomain.com`을 설정한 도메인으로 변경하세요.
{: .prompt-tip }

**비밀번호를 입력하라는 메시지가 나타나면 성공입니다!**  
WSL 계정의 비밀번호를 입력하면 원격 터미널에 접속됩니다.

---

## 트러블슈팅

### 일반적인 문제와 해결방법

#### 1. SSH 연결이 거부되는 경우
```bash
# WSL에서 SSH 서비스 상태 확인
sudo service ssh status

# SSH 서비스 재시작
sudo service ssh restart
```

#### 2. cloudflared 명령을 찾을 수 없는 경우
- Windows: 환경변수 PATH에 cloudflared 경로가 추가되었는지 확인
- 터미널을 재시작하여 PATH 변경사항 적용

#### 3. Tunnel 상태가 UNHEALTHY인 경우
```powershell
# Windows에서 cloudflared 서비스 재시작
sc stop cloudflared
sc start cloudflared
```

#### 4. 권한 거부(Permission denied) 오류
- WSL 사용자 계정의 비밀번호가 설정되어 있는지 확인
- SSH 설정에서 `PasswordAuthentication yes`가 제대로 설정되었는지 확인

---

## 보안 강화 방안

### SSH 키 기반 인증 사용

더 안전한 접속을 위해 SSH 키 기반 인증을 설정할 수 있습니다:

1. **키 쌍 생성 (접속하는 PC에서)**:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **공개 키를 WSL에 복사**:
   ```bash
   ssh-copy-id username@wsl.yourdomain.com
   ```

3. **WSL에서 비밀번호 인증 비활성화**:
   ```bash
   sudo vim /etc/ssh/sshd_config
   # PasswordAuthentication no로 변경
   sudo service ssh restart
   ```

### Cloudflare Access 정책 설정

Cloudflare Zero Trust에서 접근 정책을 설정하여 특정 이메일이나 IP에서만 접속할 수 있도록 제한할 수 있습니다.

---

## 결론

Cloudflare Tunnel을 이용하면 복잡한 네트워크 설정 없이도 안전하고 편리하게 WSL 환경에 원격 접속할 수 있습니다. 

이 방법의 주요 장점은:
- 🔒 **보안**: 모든 통신이 암호화되고 Cloudflare의 보안 인프라를 활용
- 🌐 **접근성**: 어떤 네트워크에서든 고정 도메인으로 접속 가능
- ⚡ **간편성**: 포트포워딩이나 공인 IP 설정 불필요
- 💰 **비용 효율성**: Cloudflare의 무료 플랜으로도 충분히 활용 가능

이제 언제 어디서든 개발 환경에 안전하게 접속할 수 있습니다! 
