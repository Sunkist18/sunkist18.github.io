---
title: "Cloudflare 터널과 WSL2 쿠버네티스 Ingress 연동 및 502 에러 해결법"
date: 2025-07-01 23:54:00 +0900
categories: ['Dev-Log', 'On-Premise']
tags: ['WSL2', 'Kubernetes', 'Cloudflare', 'Tunnel', 'Ingress', 'Port Forwarding', 'Troubleshooting']
description: "WSL2 쿠버네티스 환경을 Cloudflare 터널과 연동할 때 발생하는 502 Bad Gateway 에러의 근본 원인을 분석하고, 포트 포워딩 자동화 스크립트를 통한 완전한 해결책을 제시합니다."
---

**1. 개요**

이 문서는 Docker Desktop 없이 순수 WSL2에 구축한 쿠버네티스 환경을 Cloudflare 터널과 연동할 때 발생하는 **502 Bad Gateway** 에러의 근본적인 원인을 분석하고, 이를 해결하기 위한 포트 포워딩 자동화 스크립트까지 구축하는 완전한 가이드입니다.

**2. 문제 상황**

- WSL2에 k3s 등으로 쿠버네티스 클러스터 구축 완료.
- Nginx Ingress Controller를 설치하고, 애플리케이션 배포 및 Ingress 규칙 설정 완료.
- WSL2 내부에서 `curl`을 통한 테스트는 성공.
- 하지만 **윈도우**에서 실행 중인 Cloudflare 터널을 통해 외부 도메인으로 접속 시, 502 Bad Gateway 에러 발생.

**3. 원인 진단 및 단계별 해결 과정**

502 에러는 중간 게이트웨이(Nginx Ingress)가 최종 목적지(애플리케이션)와 통신하지 못했다는 신호입니다. 아래 단계를 통해 원인을 정확히 찾아 해결할 수 있습니다.

### 3-1. Ingress Controller가 규칙을 인지하는가?

먼저 Ingress Controller가 우리의 규칙을 제대로 인식하고 있는지 로그를 통해 확인합니다.

- **진단:** 아래 명령어로 실시간 로그를 확인하면서 외부에서 접속을 시도합니다.
    
    ```bash
    kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f
    ```
    
- **증상:** 로그에 아무런 변화가 없다.
- **원인:** Ingress 규칙(`ingress.yaml`)에 `ingressClassName`이 지정되지 않아 Nginx 컨트롤러가 규칙을 무시함.
- **해결책:** `ingress.yaml` 파일의 `spec` 하위에 `ingressClassName: nginx`를 추가하고 재배포합니다.

### 3-2. 윈도우와 WSL2의 네트워크는 연결되어 있는가? (핵심 원인)

`ingressClassName`을 추가해도 문제가 해결되지 않는다면, 이는 윈도우와 WSL2 간의 네트워크 단절 문제입니다.

- **증상:** 502 에러가 여전히 발생.
- **원인:** Cloudflare 터널은 **윈도우**의 `localhost`로 요청을 보냅니다. 하지만 쿠버네티스 클러스터는 **WSL2**라는 별개의 IP를 가진 가상 머신 안에서 실행됩니다. 윈도우와 WSL2의 `localhost`는 서로 다르므로 요청이 전달되지 않습니다.
- **해결책:** 윈도우의 80번 포트로 들어온 요청을 WSL2의 IP와 포트로 전달해주는 **포트 포워딩** 규칙을 윈도우에 직접 설정해야 합니다.

**4. 최종 해결책: 포트 포워딩 자동화**

WSL2의 IP는 재시작 시 변경될 수 있으므로, 이 포트 포워딩 과정을 자동화하는 것이 필수적입니다. 아래 스크립트는 이 모든 과정을 자동으로 처리해 줍니다.

### 4-1. 최종 자동화 스크립트 작성

아래 코드를 `wsl_port_forward.ps1` 등의 이름으로 원하는 위치(예: `C:\Scripts`)에 저장합니다.

```powershell
# wsl_port_forward.ps1 (English Logging, Final Version)

# --- Settings ---
$scriptDir = $PSScriptRoot
$logFilePath = Join-Path $scriptDir "log_$(Get-Date -f 'yyyy-MM-dd_HH-mm-ss').txt"

# --- Logging Function ---
function Write-Log {
    param([string]$Message)
    Write-Host $Message
    Add-Content -Path $logFilePath -Value $Message
}

try {
    Write-Log "===== Script execution started: $(Get-Date) ====="

    # Get the first 'main' IP address from WSL, handling multiple IPs
    $wsl_ip = ((wsl hostname -I).Trim() -split ' ')[0]
    Write-Log "Detected WSL main IP: $wsl_ip"

    # Get NodePort, using 'k3s kubectl' and running as root to avoid permission errors
    Write-Log "Fetching NodePort from Ingress Controller..."
    $node_port = (wsl -u root -e k3s kubectl get service ingress-nginx-controller -n ingress-nginx --no-headers -o=jsonpath='{.spec.ports[?(@.port==80)].nodePort}').Trim()
    Write-Log "Detected NodePort: $node_port"

    if (-not $wsl_ip -or -not $node_port) {
        throw "Fatal Error: Failed to get WSL IP or NodePort. Halting script."
    }

    # Reset and add the new port forwarding rule
    Write-Log "Resetting existing port forwarding rules..."
    netsh interface portproxy reset | Out-Null
    Write-Log "Adding new rule: Windows(0.0.0.0):80 -> WSL($wsl_ip):$node_port"
    netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=$node_port connectaddress=$wsl_ip | Out-Null

    Write-Log "Port forwarding has been set up successfully."
}
catch {
    $errorMessage = "!!!!! An error occurred !!!!!`n$($_.Exception.Message)"
    Write-Log $errorMessage
}
finally {
    Write-Log "===== Script execution finished: $(Get-Date) ====="
}
```

### 4-2. 스크립트 실행 환경 설정

1. **PowerShell을 관리자 권한으로 실행**합니다.
2. 아래 명령어를 입력하여 로컬 스크립트 실행을 허용합니다. (최초 1회만 필요)
    
    ```powershell
    Set-ExecutionPolicy RemoteSigned
    ```

### 4-3. 윈도우 작업 스케줄러 등록

1. `taskschd.msc`를 실행해 **작업 스케줄러**를 엽니다.
2. **[작업 만들기]**를 클릭하고 아래와 같이 설정합니다.
    - **[일반] 탭:**
        - 이름: `WSL Port Forwarding`
        - **보안 옵션**: **`사용자가 로그온할 때만 실행`**을 선택합니다. (이 방법은 계정 비밀번호가 필요 없어 편리합니다.)
        - **`가장 높은 수준의 권한으로 실행`**에 반드시 체크합니다.
    - **[트리거] 탭:**
        - **[새로 만들기]** 클릭 후, 작업 시작을 **`로그온할 때`**로 설정합니다.
    - **[동작] 탭:**
        - **[새로 만들기]** 클릭
        - 프로그램/스크립트: `powershell.exe`
        - 인수 추가: `-File "C:\Scripts\wsl_port_forward.ps1"` (스크립트 저장 경로)
    - **[조건] 탭:**
        - 노트북 사용자라면 **`컴퓨터의 AC 전원이 켜져 있는 경우에만 작업 시작`**을 체크 해제합니다.
3. **[확인]**을 눌러 저장합니다.

이제 윈도우에 로그인할 때마다 이 스크립트가 자동으로 실행되어, WSL의 IP가 바뀌더라도 포트 포워딩을 자동으로 갱신해 줍니다. 이로써 Cloudflare 터널과 WSL2 쿠버네티스 환경이 완벽하게 연동됩니다. 
