---
title: "WSL에서 k3s 설치 후 kubectl 기본 설정 및 트러블슈팅 가이드"
date: 2025-06-28 00:49:00 +0900
categories: ['Dev-Log', 'On-Premise']
tags: ['WSL', 'k3s', 'Kubernetes', 'kubectl', 'Troubleshooting']
description: "WSL 환경에 경량 쿠버네티스 k3s를 설치하고, 초기 설정 중 발생하는 일반적인 문제들을 해결하는 트러블슈팅 가이드입니다."
---

이 문서는 Windows Subsystem for Linux (WSL) 환경에 경량 쿠버네티스인 k3s를 설치하고, 설치 후 발생할 수 있는 일반적인 문제들을 해결하는 과정을 담은 트러블슈팅 가이드입니다.

### 시나리오

WSL2 환경에 k3s를 설치하여 로컬 쿠버네티스 개발 환경을 구축하는 것을 목표로 합니다. 이 과정에서 두 가지 대표적인 문제를 마주하고 해결합니다.

1. **권한 문제**: 일반 사용자로 `kubectl` 실행 시 발생하는 `permission denied` 에러 해결
2. **k3s 서비스 실패**: k3s 서비스가 `status=1/FAILURE`로 시작되지 않는 문제 해결

---

### 1단계: k3s 설치 및 최초 문제 봉착

WSL 터미널을 열고 공식 스크립트를 통해 k3s를 설치합니다.

```bash
curl -sfL https://get.k3s.io | sh -
```

설치 후 `kubectl` 명령어로 클러스터 상태를 확인하려 했으나, 첫 번째 문제에 부딪힙니다.

**[문제 1] `kubectl` 권한 오류 (Permission Denied)**

```bash
$ kubectl get nodes
WARN[0000] Unable to read /etc/rancher/k3s/k3s.yaml...
error: error loading config file "/etc/rancher/k3s/k3s.yaml": permission denied
```

- **분석**: k3s는 `root` 권한으로 설치되어 설정 파일(`k3s.yaml`) 또한 `root` 소유입니다. 일반 사용자는 이 파일에 접근할 수 없어 `kubectl`이 클러스터 정보를 읽어오지 못합니다.
- **해결**: `root`의 설정 파일을 일반 사용자 홈 디렉토리로 복사하고, `kubectl`이 해당 파일을 기본으로 사용하도록 `KUBECONFIG` 환경 변수를 설정합니다.

    ```bash
    # 1. ~/.kube 디렉토리 생성
    mkdir -p ~/.kube
    
    # 2. 설정 파일 복사 및 소유자 변경
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    
    # 3. KUBECONFIG 환경 변수 영구 설정
    echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
    source ~/.bashrc
    ```

이제 `kubectl get nodes`를 실행하면 권한 문제는 해결되어야 합니다. 
하지만, 이번엔 다른 문제가 발생했습니다.

---

### 2단계: k3s 서비스 실행 실패 문제 해결

권한 문제를 해결했음에도 불구하고 `kubectl`이 여전히 클러스터에 접속하지 못합니다. k3s 서비스의 상태를 직접 확인해 봅니다.

```bash
$ sudo systemctl status k3s
● k3s.service - Lightweight Kubernetes
     ...
     Active: activating (auto-restart) (Result: exit-code) ...
...
Jun 28 00:27:50 DESKTOP-260CR3P systemd[1]: k3s.service: Main process exited, code=exited, status=1/FAILURE
```

서비스가 계속 재시작되며 `status=1/FAILURE` 상태에 빠져 있습니다. 더 자세한 원인을 찾기 위해 `journalctl`로 시스템 로그를 확인합니다.

```bash
sudo journalctl -u k3s -f
```

**[문제 2] 스왑(Swap) 메모리로 인한 Kubelet 시작 실패**

로그를 분석하던 중 결정적인 에러 메시지를 발견했습니다.

```
E0628 00:27:49.823218   26357 kubelet.go:1643] "Failed to start ContainerManager" err="system validation failed - wrong number of fields (expected 6, got 7)"
```

- **분석**: 이 에러는 쿠버네티스의 핵심 컴포넌트인 Kubelet이 시스템 유효성 검사에 실패했음을 의미합니다. 로그의 앞부분에서 `Swap is on`이라는 메시지를 통해, **시스템의 스왑 메모리가 활성화**되어 있는 것이 원인임을 확인했습니다. 쿠버네티스는 안정적인 성능을 위해 스왑 비활성화를 강력히 권장하며, 활성화된 경우 Kubelet 시작을 거부할 수 있습니다.
- **해결 (WSL 환경)**: WSL2에서는 일반 리눅스와 다른 방식으로 스왑을 제어해야 합니다.
    1. **임시 비활성화로 문제 확인**: 먼저 `swapoff` 명령어로 스왑을 임시로 끄고 `k3s`가 정상 실행되는지 확인합니다.
        
        ```bash
        sudo swapoff -a
        sudo systemctl restart k3s
        ```
        
        `sudo systemctl status k3s`를 실행하여 서비스가 `active (running)` 상태가 되면 스왑이 원인이었음이 확실해집니다.
        
    2. **영구 비활성화 (WSL2 방식)**: WSL 재시작 시 스왑이 다시 켜지는 것을 막기 위해, Windows 사용자 폴더(`C:\Users\<Your-Username>\`)에 `.wslconfig` 파일을 생성하거나 수정하여 아래 내용을 추가합니다.
        
        ```
        # .wslconfig
        [wsl2]
        swap=0
        ```
        
    3. **WSL 재시작**: Windows의 PowerShell 또는 CMD에서 아래 명령어를 실행하여 WSL을 완전히 종료합니다. 이후 WSL 터미널을 다시 열면 설정이 적용됩니다.
        
        ```powershell
        wsl --shutdown
        ```

---

### 최종 결과

위 두 가지 트러블슈팅을 마친 후, WSL 터미널에서 `kubectl` 명령어를 실행하면 드디어 정상적으로 클러스터 정보를 반환합니다.

```bash
$ kubectl get nodes
NAME                STATUS   ROLES                  AGE   VERSION
desktop-260cr3p     Ready    control-plane,master   5m    v1.28.4+k3s2
```

이로써 WSL 환경에 k3s를 성공적으로 설치하고, 초기 설정 및 주요 문제 해결을 완료하여 안정적인 로컬 쿠버네티스 개발 환경을 구축했습니다. 
