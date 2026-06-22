---
title: "클라우드활용 10주차 — AWS 계정 관리: Organizations·SCP & CloudTrail 감사"
date: 2026-05-14 21:30:00 +0900
categories: [Dev, DevOps]
tags: [클라우드활용, AWS, Organizations, CloudTrail]
description: "다계정 거버넌스(Organizations·OU·SCP) 개념과 CloudTrail 감사를 다룬 10주차 기록. CloudTrail lookup-events로 내 API 활동 로그를 직접 추적했다."
image: assets/img/20260514/lecture_cloudtrail_events.jpg
---

10주차는 **다계정 환경의 거버넌스** — AWS Organizations(조직)·OU·**SCP(서비스 제어 정책)** 와, "누가 무슨 일을 했는지" 추적하는 **CloudTrail 감사** 를 다룬다. Organizations는 단일 계정이라 생성이 불가능해 개념+강의 화면으로, CloudTrail 감사는 CLI로 조회해 활동 로그를 직접 추적했다.

## 핵심 개념

### AWS Organizations & SCP

- **Organizations**: 여러 AWS 계정을 **하나의 조직** 으로 묶어 중앙 관리한다. 구조: `루트(조직) → 관리 계정 → OU(조직 단위) → 멤버 계정`.
- **OU(Organizational Unit)**: 계정을 용도(재무팀/개발팀 등)별로 묶는 폴더.
- **SCP(Service Control Policy)**: OU·계정에 적용하는 **권한 상한선(guardrail)**. IAM이 "허용"해도 SCP가 막으면 못 한다 — 예: "특정 리전 외 사용 금지", "루트 사용자 작업 제한".
- **목적**: 비용 통제, 보안 표준 강제, 환경 격리.

### CloudTrail (감사·추적)

- AWS에서 일어나는 **모든 API 활동을 기록** 한다. "어느 날 EC2가 종료됐다 → 누가, 왜 종료했나"를 추적할 수 있다.
- 보안 감사·문제 진단·규정 준수·사고 분석에 활용한다.

## 강의 화면 — CloudTrail 이벤트 기록

![CloudTrail 이벤트 기록(관리 이벤트)](assets/img/20260514/lecture_cloudtrail_events.jpg)
_CloudTrail 콘솔의 이벤트 기록 — `PutMetricAlarm`·`CreateWorkload` 등 API 호출을 사용자·시간·리소스와 함께 추적한다._

## 거버넌스 조회

### Organizations 상태 확인

```bash
$ aws organizations describe-organization
AWSOrganizationsNotInUseException
```

이 계정은 **단일 계정** 으로 조직이 구성돼 있지 않다. 멤버 계정·SCP를 만들려면 추가 계정이 필요해 실제 생성은 개념과 강의 화면으로 대체했다.

### CloudTrail 보안 감사 — "누가 무슨 일을 했는가"

```bash
$ aws cloudtrail lookup-events --max-results 8 \
    --query "Events[].[EventName,Username,EventSource]" --output text
ListDetectors              admin   guardduty.amazonaws.com
DescribeRegions            admin   ec2.amazonaws.com
DescribeAvailabilityZones  admin   ec2.amazonaws.com
GetAccountPublicAccessBlock admin  s3.amazonaws.com
DescribeAlarms             admin   monitoring.amazonaws.com
CreateLogGroup             admin   logs.amazonaws.com

# 특정 이벤트(EC2 생성) 추적 — 5주차에 띄운 인스턴스가 감사 로그에 남아 있다
$ aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances --max-results 2 \
    --query "Events[].[EventName,Username]" --output text
RunInstances   admin
RunInstances   admin
```

CloudTrail이 그동안 실행한 API 호출을 기록하고 있어, `admin` 사용자가 어떤 서비스에 무슨 작업을 했는지 추적할 수 있다. 5주차 `RunInstances`(EC2 생성)까지 감사 로그로 확인된다.

## 정리

다계정 거버넌스(Organizations·SCP)는 *"IAM은 계정 안, SCP는 계정 위에서 권한 상한을 친다"* 는 2층 구조로 정리된다. 단일 계정이라 직접 만들지는 못했지만 IAM과의 차이를 개념으로 구분했다. CloudTrail은 `lookup-events` 로 실제 수행한 행동(EC2 생성·각종 조회)이 감사 로그에 남는 것을 확인할 수 있어, Well-Architected의 보안 기둥(추적성)이 무엇인지 보여준다.
