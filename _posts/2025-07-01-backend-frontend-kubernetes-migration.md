---
title: "백엔드+프론트엔드 서비스 쿠버네티스 마이그레이션"
date: 2025-07-01 23:59:00 +0900
categories: ['Dev-Log', 'On-Premise']
tags: ['Kubernetes', 'Migration', 'Microservices', 'Docker', 'Streamlit', 'Flask', 'Ingress']
description: "단일 서버의 docker-compose 환경에서 실행되던 프론트엔드/백엔드 서비스를 쿠버네티스 클러스터의 독립적인 마이크로서비스로 마이그레이션하는 과정과 주요 트러블슈팅을 다룹니다."
---

## 1. 개요

- **목표:** 단일 서버에서 `docker-compose`로 실행되던 프론트엔드/백엔드 서비스를 쿠버네티스 클러스터의 독립적인 마이크로서비스로 전환합니다.
- **핵심 전략:** "하나의 서비스, 하나의 폴더" 원칙에 따라 `web-frontend` (Streamlit)와 `api-backend` (Flask)를 별개의 쿠버네티스 리소스로 분리하여 배포하고, 서비스 간 통신은 클러스터 내부에서 처리하도록 구성합니다.

---

## 2. 아키텍처 변경: 서비스 분리

### 2.1. Dockerfile 분리

기존의 단일 `Dockerfile`은 Streamlit 프론트엔드 실행을 기본으로 하고 있었습니다. 두 서비스를 독립적으로 배포하기 위해, 각 서비스에 맞는 별도의 Dockerfile을 생성했습니다.

- **`Dockerfile.front`**: Streamlit 프론트엔드를 실행합니다.
    
    ```dockerfile
    # ... (공통 설정) ...
    EXPOSE 8501
    CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501"]
    ```
    
- **`Dockerfile.back`**: Flask 백엔드 서버를 실행합니다.
    
    ```dockerfile
    # ... (공통 설정) ...
    EXPOSE 5000
    CMD ["python", "api_server.py"]
    ```

### 2.2. 쿠버네티스 리소스 구성

`deployment_rules.txt`에 따라, `deploy` 디렉토리 하위에 각 서비스별로 폴더를 생성하고 필요한 리소스를 정의했습니다.

- **`deploy/web-frontend/`**: 프론트엔드 관련 모든 리소스 포함
    - `deployment.yaml`, `service.yaml`, `ingress.yaml`, `kustomization.yaml`
- **`deploy/api-backend/`**: 백엔드 관련 모든 리소스 포함
    - `deployment.yaml`, `service.yaml`, `kustomization.yaml`

---

## 3. 서비스 간 통신과 외부 노출

### 3.1. 내부 통신: ClusterIP

프론트엔드가 백엔드를 안정적으로 찾을 수 있도록, 백엔드 서비스를 **`ClusterIP`** 타입으로 생성했습니다.

- **`deploy/api-backend/service.yaml`**
    
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: api-backend
    spec:
      selector:
        app: api-backend
      ports:
        - port: 5000
          targetPort: 5000
    ```
    
- **작동 원리:**
    1. 위 `Service`가 생성되면, 쿠버네티스는 클러스터 내부 DNS에 `api-backend`라는 고유한 호스트 이름을 등록합니다.
    2. `web-frontend` 애플리케이션은 코드 수정 없이 `http://api-backend:5000` 주소로 백엔드에 요청을 보낼 수 있습니다.
    3. 쿠버네티스가 `api-backend`라는 이름을 실제 백엔드 Pod의 IP로 자동 연결해줍니다.

### 3.2. 외부 노출: Ingress

외부 도메인(`app.example.local`)으로 들어오는 트래픽을 경로에 따라 적절한 서비스로 분배하기 위해 Ingress를 사용했습니다.

- **`deploy/web-frontend/ingress.yaml`**
    
    ```yaml
    # ...
    rules:
    - host: app.example.local
      http:
        paths:
        - path: /api # 백엔드로 가야 할 경로
          pathType: Prefix
          backend:
            service:
              name: api-backend
              port: { number: 5000 }
        # ... (/data, /health 등 다른 백엔드 경로들) ...
        - path: / # 그 외 모든 경로
          pathType: Prefix
          backend:
            service:
              name: web-frontend
              port: { number: 80 }
    ```

---

## 4. 핵심 트러블슈팅 과정

마이그레이션 중 발생했던 주요 문제와 해결 과정을 공유합니다.

### 4.1. 문제: Pod의 이미지 로딩 실패 (`ImagePullBackOff`)

- **현상:** `kubectl get pods` 실행 시, Pod가 이미지를 가져오지 못하고 계속 재시작하는 오류 발생.
- **원인 분석:**
    1. `deployment.yaml`에 `imagePullPolicy`가 명시되지 않으면 기본값인 `Always`로 설정됩니다. 이 경우 쿠버네티스는 항상 원격 레지스트리에서 이미지를 가져오려고 시도합니다.
    2. 우리는 `docker build`로 로컬에 이미지를 생성하고 `k3s ctr images import`로 k3s 내부 스토리지에 직접 로드했으므로, 원격 레지스트리에는 해당 이미지가 존재하지 않았습니다.
    3. 또한, `:latest` 태그는 변경 사항이 있어도 노드가 새 이미지를 받아오지 않는 문제를 유발할 수 있습니다.
- **해결 방안:**
    1. **`imagePullPolicy` 명시:** `deployment.yaml`에 `imagePullPolicy: IfNotPresent`를 추가하여, 로컬에 이미지가 있으면 원격에서 가져오지 않도록 설정했습니다.
    2. **명시적 버전 태그 사용:** `:latest` 대신 `:v1`과 같은 명확한 버전 태그를 사용하도록 정책을 변경했습니다.
    
    ```yaml
    # deployment.yaml 수정 예시
    spec:
      containers:
      - name: web-frontend
        image: web-frontend:v1
        imagePullPolicy: IfNotPresent # <-- 이 줄 추가
    ```

### 4.2. 문제: Ingress를 통한 백엔드 라우팅 오류

- **현상:** `app.example.local/api`로 접속 시, 의도한 API 페이지가 아닌 "Flask server is running." 이라는 백엔드의 기본 응답만 표시됨.
- **원인 분석:**
    - `ingress.yaml`에 포함된 `nginx.ingress.kubernetes.io/rewrite-target: /` 어노테이션이 문제였습니다.
    - 이 어노테이션은 Ingress로 들어온 요청의 경로를 `/`로 강제로 변경하여 백엔드에 전달합니다. 따라서 `/api` 요청이 백엔드 Flask 서버에는 `/` 요청으로 전달되었고, `@app.route("/")`에 정의된 기본 핸들러가 실행된 것입니다.
- **해결 방안:**
    - `ingress.yaml`에서 `annotations` 섹션의 `rewrite-target` 줄을 완전히 **삭제**했습니다.
    - 이를 통해 `/api` 요청이 백엔드 서비스에 그대로 전달되어, `@app.route("/api")` 핸들러가 정상적으로 호출되도록 수정했습니다.

---

## 5. 최종 배포 워크플로우

1. **소스 코드 준비:**
    - 소스 코드는 `~/web-application`에 위치합니다.
    - 쿠버네티스 배포 설정은 `~/deploy`에 위치합니다.
2. **이미지 빌드** (`v1` 태그 사용):
    
    ```bash
    # 프론트엔드 이미지 빌드
    docker build -t web-frontend:v1 -f web-application/Dockerfile.front web-application/
    
    # 백엔드 이미지 빌드
    docker build -t api-backend:v1 -f web-application/Dockerfile.back web-application/
    ```
    
3. **k3s로 이미지 로드**:
    
    ```bash
    # 프론트엔드 이미지 로드
    docker save web-frontend:v1 | sudo k3s ctr images import -
    
    # 백엔드 이미지 로드
    docker save api-backend:v1 | sudo k3s ctr images import -
    ```
    
4. **쿠버네티스에 배포**:
    
    ```bash
    # deploy 디렉토리의 모든 리소스 적용
    kubectl apply -k deploy/
    ``` 
