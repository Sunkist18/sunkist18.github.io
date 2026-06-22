---
title: "클라우드활용 7주차 — 클라우드 보안: 공동 책임 모델·WAF·GuardDuty & Well-Architected"
date: 2026-04-23 21:30:00 +0900
categories: [Dev, DevOps]
tags: [클라우드활용, AWS, 보안, WellArchitected]
description: "공동 책임 모델, 보안 서비스(WAF·GuardDuty·Shield), Well-Architected 6대 기둥을 정리하고 GuardDuty 탐지기 상태를 조회해 본 7주차 기록."
image: assets/img/20260423/lecture_http_flood_waf.jpg
---

7주차는 클라우드 보안의 큰 그림을 다룬다. **공동 책임 모델**, 보안 서비스(**WAF·GuardDuty·Shield**), 그리고 **AWS Well-Architected Framework 6대 기둥** 이다. 개념 중심 주차라 강의 내용을 정리하고, 조회 가능한 부분(GuardDuty 탐지기 상태)은 CLI로 확인했다.

## 핵심 개념

### 공동 책임 모델 (Shared Responsibility Model)

- **AWS 책임 ("of the cloud")**: 물리 데이터센터, 하드웨어, 하이퍼바이저, 네트워크 인프라 보안.
- **고객 책임 ("in the cloud")**: 데이터 암호화, **IAM 권한 설정**, OS·애플리케이션 패치, 보안 그룹/네트워크 구성.
- AWS가 안전한 인프라를 제공해도 IAM·S3 공개설정 같은 "내 몫"을 틀리면 사고가 난다.

### 주요 보안 서비스

- **WAF(Web Application Firewall)**: 웹 계층(L7) 공격 차단. SQL Injection·XSS·**HTTP Flood**(속도 기반 룰)를 필터링.
- **Shield**: DDoS 방어(L3/L4). Standard는 자동·무료, Advanced는 유료 고급 보호.
- **GuardDuty**: 위협 탐지 서비스. CloudTrail·VPC Flow Logs·DNS 로그를 ML로 분석해 이상행위를 탐지.

### Well-Architected Framework — 6대 기둥

1. **운영 우수성(Operational Excellence)** — 자동화·모니터링·지속 개선
2. **보안(Security)** — 최소 권한·데이터 보호·추적성
3. **안정성(Reliability)** — 장애 복구·다중화
4. **성능 효율성(Performance Efficiency)** — 적절한 자원 선택·확장
5. **비용 최적화(Cost Optimization)** — 사용량 기반·낭비 제거
6. **지속 가능성(Sustainability)** — 자원 효율로 환경 영향 최소화

## 강의 화면 — 웹 공격과 WAF 대응

![HTTP Flood 공격과 WAF 속도 기반 룰 완화](assets/img/20260423/lecture_http_flood_waf.jpg)
_다수 봇이 서버에 `HTTP GET FLOOD` 를 보내 서비스 불능을 유도하는 HTTP Flood — **WAF의 Rate-based Rule** 로 완화한다._

## GuardDuty 상태 조회

위협 탐지 서비스 GuardDuty가 이 계정/리전에서 활성화돼 있는지 확인했다.

```bash
$ aws guardduty list-detectors --region ap-northeast-2 --query "DetectorIds" --output json
[]
```

탐지기 목록이 비어 있으면 아직 활성화 전 상태다. GuardDuty는 활성화하면 탐지기(detector)가 생성되고, 이후 CloudTrail/VPC Flow Logs/DNS 로그를 분석해 이상행위를 탐지한다. (활성화는 과금 가능성이 있어 조회만 수행했다.)

## 정리

보안은 *AWS가 알아서 해주는 것* 이 아니라 **공동 책임** 이다. IAM(내 몫)·S3 공개설정(내 몫)이 왜 중요한지가 이 모델로 한 번에 정리된다. WAF/Shield/GuardDuty는 각각 **L7 공격 / DDoS / 위협 탐지** 를 담당한다. Well-Architected 6대 기둥은 이 과목 전체의 목차와도 겹친다 — 보안, 안정성, 비용 최적화, 성능/운영이 개별 실습들을 하나의 "잘 설계된 아키텍처" 프레임으로 묶어준다.
