---
title: "클라우드활용 9주차 — 클라우드 아키텍처 기초 & CloudWatch 모니터링"
date: 2026-05-07 22:00:00 +0900
categories: [Dev, DevOps]
tags: [클라우드활용, AWS, 아키텍처, CloudWatch]
description: "컴퓨팅·스토리지·DB·네트워크의 조합과 RDS 확장성 같은 아키텍처 기초를 정리하고, CloudWatch가 수집 중인 지표 네임스페이스를 조회해 본 9주차 기록."
image: assets/img/20260507/lecture_rds_scaling.jpg
---

9주차는 **AWS 아키텍처의 기초 구성 요소**(컴퓨팅·스토리지·DB·네트워크의 조합, RDS 확장성)와 운영의 핵심인 **CloudWatch 모니터링** 을 다룬다. 아키텍처 설계는 개념·강의 화면으로, CloudWatch는 CLI로 조회해 정리했다.

## 핵심 개념

### AWS 아키텍처 기초 구성 요소

- 좋은 아키텍처는 **컴퓨팅(EC2)·스토리지(EBS/S3)·데이터베이스(RDS)·네트워크(VPC)** 를 목적에 맞게 조합한 것이다.
- **RDS(관리형 DB)의 확장성**
  - **수직 확장(Scale-up)**: 더 큰 인스턴스 타입으로 교체.
  - **수평 확장(Scale-out)**: **읽기 전용 복제본(Read Replica)** 추가로 읽기 처리량 분산.
- 아키텍처 설계 시 *Production/Development VPC 분리*, *피어링*, *접근 제어* 등으로 환경을 격리한다.

### CloudWatch 모니터링

- **지표(Metrics)**: CPU·네트워크·디스크 등 수치 시계열. 서비스별 **네임스페이스** 로 구분(`AWS/EC2` 등).
- **로그(Logs)**: 애플리케이션/시스템 로그 수집, **Log Insights** 로 쿼리.
- **대시보드/경보(Alarm)**: 시각화 + 임계 초과 시 SNS 알림.

## 강의 화면 — 아키텍처 기초(RDS 확장성)

![AWS 아키텍처의 기초 요소: RDS 인스턴스의 수직/수평 확장](assets/img/20260507/lecture_rds_scaling.jpg)
_RDS는 **수직 확장(더 큰 인스턴스)** 과 **수평 확장(읽기 전용 복제본 추가)** 으로 부하를 처리한다._

## CloudWatch 수집 대상 조회

이 계정에서 CloudWatch가 현재 지표를 수집 중인 **네임스페이스** 를 조회했다.

```bash
$ aws cloudwatch list-metrics --query "Metrics[].Namespace" --output text | tr '\t' '\n' | sort -u
AWS/EBS          # EBS 볼륨 지표
AWS/EC2          # EC2 인스턴스 지표(CPU 등 — 5주차에서 수집 확인)
AWS/Logs         # CloudWatch Logs 관련
AWS/Usage        # 서비스 사용량
```

앞 주차 실습이 남긴 지표 네임스페이스가 그대로 보인다(5주차 EC2의 `AWS/EC2` 등). 모니터링이 별도 설정 없이도 자원 생성과 함께 자동으로 시작됨을 확인할 수 있다.

## 정리

따로 다룬 EC2·S3·VPC·RDS가 결국 하나의 **아키텍처로 조합** 된다는 관점을 정리했다. 특히 RDS의 읽기 복제본(수평 확장)은 고가용성(Multi-AZ)과 맞닿아 있다. CloudWatch 네임스페이스를 조회하면 5주차에 띄운 EC2가 `AWS/EC2` 에 쌓여 있어, 실습 이력이 모니터링 데이터로 남는다는 것을 확인할 수 있다.
