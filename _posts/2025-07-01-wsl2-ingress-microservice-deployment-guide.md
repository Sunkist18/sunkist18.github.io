---
title: "WSL2에서 Ingress를 활용한 마이크로서비스 배포 환경 구축 A-Z"
date: 2025-07-01 23:46:00 +0900
categories: ['Dev-Log', 'On-Premise']
tags: ['WSL2', 'Kubernetes', 'Ingress', 'Microservices', 'Kustomize', 'Nginx']
description: "WSL2 환경에서 Docker Desktop 없이 Nginx Ingress Controller와 Kustomize를 활용하여 마이크로서비스 배포 환경을 구축하고, 초기 설정 중 발생하는 문제들을 해결하는 가이드입니다."
---

**1. 개요**

이 문서는 Docker Desktop 없이 순수 WSL2 환경에서, Kustomize와 Nginx Ingress Controller를 사용하여 확장 가능하고 유지보수가 용이한 쿠버네티스 마이크로서비스 배포 환경을 구축하는 모든 과정을 다룹니다.

이 가이드를 통해 각 서비스가 자신의 배포 설정을 독립적으로 관리하는 효율적인 GitOps 기반 아키텍처를 완성할 수 있습니다.

**2. 준비물**

- WSL2 (Ubuntu 등)
- `kubectl` 커맨드라인 툴
- WSL2 내부에 설치된 쿠버네티스 클러스터 (예: k3s, Minikube, KinD)

**3. 1단계: Kustomize를 활용한 디렉토리 구조 설계**

마이크로서비스 아키텍처의 핵심은 각 서비스의 독립성입니다. `kustomize`를 사용하여 각 서비스가 자신의 배포 관련 모든 파일(`Deployment`, `Service`, `Ingress` 등)을 가지도록 구조를 설계합니다.

```
/deploy
├── backend-api/           # <--- 서비스 A
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
├── user-service/          # <--- 서비스 B (미래에 추가될)
│   ├── ...
│   └── kustomization.yaml
└── kustomization.yaml     # <--- 최상위 Kustomization
```

- **`deploy/<서비스명>/kustomization.yaml`**: 각 서비스에 필요한 모든 쿠버네티스 리소스를 정의합니다.
    
    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
    - deployment.yaml
    - service.yaml
    - ingress.yaml
    ```
    
- **`deploy/kustomization.yaml`**: 전체 환경에 배포할 서비스들의 목록을 관리합니다.
    
    ```yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - backend-api
      # - user-service  #<- 새 서비스는 여기에 한 줄만 추가하면 됨
    ```

**4. 2단계: Nginx Ingress Controller 설치**

클러스터 외부의 요청을 내부 서비스로 연결해 줄 트래픽 경찰, Nginx Ingress Controller를 설치합니다.

```bash
# Nginx Ingress Controller 설치
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# 설치 확인 (ingress-nginx 네임스페이스의 Pod이 Running 상태가 될 때까지 확인)
kubectl get pods -n ingress-nginx
```

**5. 3단계: 쿠버네티스 리소스 정의 (`deployment`, `service`, `ingress`)**

각 서비스 폴더에 필요한 파일을 작성합니다. 여기서 가장 중요한 것은 `ingress.yaml`에 `ingressClassName: nginx`를 명시하여, 이 규칙이 Nginx 컨트롤러의 책임임을 알려주는 것입니다.

- `deployment.yaml`: 애플리케이션 파드를 정의합니다.
- `service.yaml`: 파드에 안정적인 내부 네트워크 주소를 제공합니다.
- `ingress.yaml`: 외부 요청을 서비스로 연결하는 규칙을 정의합니다.
    
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: backend-api-ingress
    spec:
      ingressClassName: nginx # <-- 매우 중요!
      rules:
      - host: "api.example.local"
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend-api-service
                port:
                  number: 8080 # service.yaml에 정의된 포트
    ```

**6. 4단계: 애플리케이션 배포 및 내부 테스트**

모든 준비가 끝났습니다. `kustomize`를 통해 클러스터에 애플리케이션을 배포하고 `curl`로 내부 통신이 정상적인지 확인합니다.

```bash
# 배포
kubectl apply -k deploy

# 내부 통신 테스트
curl --verbose --header "Host: api.example.local" http://127.0.0.1
```

이 `curl` 테스트가 성공하면, 클러스터 내부의 모든 설정은 완벽하게 완료된 것입니다.
