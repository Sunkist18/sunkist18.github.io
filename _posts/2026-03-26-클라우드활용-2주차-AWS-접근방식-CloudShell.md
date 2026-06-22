---
title: "클라우드활용 2주차 — AWS 접근 방식: 콘솔·CLI·SDK & CloudShell"
date: 2026-03-26 22:30:00 +0900
categories: [Dev, DevOps]
tags: [클라우드활용, AWS, CLI, CloudShell]
description: "AWS를 다루는 여러 접근 방식(콘솔/CLI/SDK/API)과 인증 구조, CloudShell을 정리하고, 로컬 AWS CLI로 STS·리전 조회를 직접 해 본 2주차 기록."
image: assets/img/20260326/lecture_console_ui.jpg
---

2주차는 AWS를 다루는 **여러 접근 방식**(웹 콘솔 / CLI / SDK / API)과 인증 구조, AWS CloudShell을 다룬다. 강의는 콘솔(GUI)·CloudShell 화면으로 진행되므로, 로컬에 AWS CLI를 구성해 같은 조회를 수행하고 콘솔/CloudShell 화면은 강의 화면으로 인용했다. 자격증명은 출력에 노출하지 않았고 계정 ID는 가렸다.

## 핵심 개념

- **AWS 접근 방식 4가지**
  - **웹 콘솔(Management Console)**: 브라우저 GUI. 직관적이고 학습·설정에 적합.
  - **CLI(Command Line Interface)**: 터미널에서 `aws ...` 명령. **재현·자동화**에 강점.
  - **SDK**: Python(boto3)·Java 등 코드에서 호출. 애플리케이션 통합용.
  - **API**: 위 모든 것의 바탕이 되는 REST 기반 인터페이스.
- **인증 주체**: **Root 사용자**(이메일+비번, 전권 — 설정 시에만) vs **IAM 사용자**(계정 ID+사용자명+비번, 또는 액세스 키). MFA로 2단계 인증을 강화한다.
- **AWS CloudShell**: 콘솔 안에서 열리는 **브라우저 기반 리눅스 셸**. 별도 키 설정 없이 로그인 세션으로 `aws` 명령을 실행한다.
- **STS(Security Token Service)**: `get-caller-identity` 로 "지금 이 호출이 누구로 인증됐는지"를 확인한다.

## 접근 방식별로 확인하기

> 강의의 CloudShell 대신, 로컬 Windows에 AWS CLI를 구성해 동일한 접근을 수행했다.
{: .prompt-info }

### CLI 설치·설정 확인

```bash
$ aws --version
aws-cli/2.35.9 Python/3.14.5 Windows/11 exe/AMD64

$ aws configure list --profile clouduse        # 자격증명은 끝 4자리도 마스킹되어 표시
      Name        Value             Type    Location
   profile    : clouduse           manual   --profile
access_key : ****************XXXX  shared-credentials-file
secret_key : ****************XXXX  shared-credentials-file
   region     : ap-northeast-2     config-file   ~/.aws/config
```

`aws configure set ... --profile clouduse` 로 자격증명을 프로필에 저장해, 명령에 키를 직접 노출하지 않는다.

### 인증 주체 확인 (STS)

```bash
$ aws sts get-caller-identity
{
    "UserId": "AIDA5SZRJB65********",
    "Account": "9337****0266",
    "Arn": "arn:aws:iam::9337****0266:user/admin"
}
```

이 호출이 `admin` IAM 사용자로 인증됐음을 확인할 수 있다. 콘솔 로그인과 동일한 신원을 CLI에서 검증하는 셈이다.

### 프로그래매틱 조회

```bash
$ aws s3 ls
(버킷 없음 — 깨끗한 계정 상태)

$ aws ec2 describe-regions \
    --query "Regions[?starts_with(RegionName, \`ap-\`)].RegionName" --output text
ap-south-1   ap-northeast-3   ap-northeast-2   ap-northeast-1   ap-southeast-1   ap-southeast-2
```

콘솔에서 클릭으로 보던 리전 목록을 CLI 한 줄로 조회한 것으로, 같은 정보를 다른 접근 방식으로 가져온 것이다.

### 강의 화면 — 콘솔 & CloudShell

강의에서는 웹 콘솔 UI와 CloudShell을 시연했다(GUI라 화면으로 인용).

![AWS Management Console 기본 UI(계정 정보 영역)](assets/img/20260326/lecture_console_ui.jpg)
_콘솔 홈의 계정 정보 영역(로그인 사용자·계정 ID, Root/IAM 여부, 보안 자격증명 메뉴)._

![CloudShell에서 `aws s3 ls` 실행](assets/img/20260326/lecture_cloudshell_s3ls.jpg)
_콘솔 내 CloudShell(`ap-northeast-2`)에서 `aws s3 ls` 로 버킷 목록을 조회하는 모습. 별도 키 설정 없이 로그인 세션으로 CLI를 쓰는 접근 방식이다._

## 정리

같은 AWS 자원을 콘솔·CLI·CloudShell 어느 쪽으로도 다룰 수 있다. 콘솔은 학습·탐색에, **CLI는 재현·자동화** 에 강해 이 기록은 CLI 중심으로 진행한다. `aws configure` 로 자격증명을 프로필에 분리 저장하면 명령에 키를 노출하지 않고도 인증되며, `sts get-caller-identity` 는 "내가 누구로 실행 중인지" 확인하는 기본 점검으로 쓰인다. CloudShell은 키를 만들지 않고도 CLI를 쓰는 선택지다.
