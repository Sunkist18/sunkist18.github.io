---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---

![](assets/img/about/me.png){: width="180" height="180" .left .shadow }

### 최민우

충남대학교 컴퓨터공학과 4학년 · 학부연구생  
백엔드와 DevOps를 실무에서 다뤘고, 현재 MCP 기반 문서 자동화를 연구하고 있습니다.

`Backend` · `DevOps` · `Automation` · `RPA`

[GitHub @Sunkist18](https://github.com/Sunkist18) · [chaeminu0711@gmail.com](mailto:chaeminu0711@gmail.com)

&nbsp;

---

## 학부 연구

> **충남대학교 데이터네트워크연구실** · 지도교수 이영석 · 학부연구생

HWP 문서 제어를 위한 **MCP(Model Context Protocol) 서버**를 설계·구현했습니다. Windows COM API와 `pyhwpx`를 MCP 프로토콜로 감싸 LLM이 HWP 문서를 자연어로 제어할 수 있도록 했고, 자기 수정(Self-Correction) 메커니즘을 도입해 표 제어 과제에서 높은 성공률을 달성했습니다.

> **KSC 2025 포스터 발표** — 한국소프트웨어종합학술대회 (2025.12., 여수)  
> _"HWP(한글) 문서 표 제어를 위한 MCP(Model Context Protocol) 설계 및 구현"_  
> 최민우·이영석, 충남대학교
{: .prompt-tip }

---

## Mockingbird

**Backend / DevOps Engineer** · 2023.09. – 2025.12. (27개월)

![](assets/img/about/mockingbird.png){: .shadow }

[**Mockingbird**](https://mockingbird.co.kr/)에서 서비스 개발부터 인프라 전환까지 주도했습니다.

### 서버 안정화 및 최적화 · 50× 개선

트위터 바이럴로 문제지 제작 서버에 트래픽이 몰려 장애가 발생했습니다. 서버 증설과 싱글턴 기반 객체 재사용 설계로 처리 속도를 **50배** 개선했습니다.

> ![](assets/img/about/an.png)
> _트래픽 급증 시점 전후 서버 요청 그래프_
{: .prompt-info }

### AWS → 온프레미스 마이그레이션

AWS 크레딧 소진에 따른 비용 절감을 위해 온프레미스 전환을 주도했습니다. Windows Server + WSL에서 시작해 docker-compose의 복구 한계를 넘어서기 위해 **k3s 클러스터**로 전환하고, **Cloudflare Tunnel + Ingress**로 외부 노출을 구성했습니다. 이후 Windows 병목을 해소하기 위해 Ubuntu 서버로 이전했습니다.

### 결제 · 장바구니 · 쿠폰 시스템

Spring과 토스 페이먼츠 API로 결제·장바구니를 구현하고, DB 스키마 설계부터 쿠폰 관리 기능까지 담당했습니다.

### 080 수신거부 서비스 도입

문자메시지 전송 로직에 080 수신거부 연동을 통합했습니다.

### B2B 외주 프로젝트

![](assets/img/about/aa.png){: .shadow }

{% include embed/video.html src='assets/video/mockingbird.mp4' poster='assets/img/about/mh.png' %}

- **개념원리 HTML → HWPX 변환기** — Python, Django, LATEX2HANTEX(자체 개발)로 변환 API 구현
- **Hidden KICE 채점 사이트** — 백엔드·DB 설계 전담, AWS 배포 및 DNS 구성
- **시대인재 AI 자막 생성 서비스** — MP4 → Whisper API → SRT 파이프라인 설계. Whisper 25MB 제한을 오디오 분할·분산 처리·타임스탬프 재조정으로 해결
- **Mockingbird B2B SaaS 문제은행** — Windows + Django 기반 구축, API·DB 설계 참여

---

## 군 복무

**공군 소프트웨어 개발병** · 2021.10. – 2023.07.

RPA 팀에서 **Python**과 **UiPath**로 행정 업무 자동화를 담당했습니다. 간부 피복비 자동 계산·지급 프로그램을 개발하고, 포상 휴가 관리 시스템을 자동화해 반복적인 서류 업무 시간을 대폭 단축시켰습니다. 이 시기에 취득한 **UiPath UIARD** 자격증은 이후 스타트업 B2B 자동화 프로젝트로 자연스럽게 이어졌습니다.

&nbsp;

---

## 이전 경험

**충남대학교 데이터네트워크 연구실** — 학부연구생  
_2021.05. – 2021.10._

- Django와 Chart.js로 DMOJ 온라인 저지 사이트의 통계·차트 기능 개선
- Python과 Discord API로 튜터 매칭 디스코드 봇 개발
- Ubuntu 환경 서버 구축 및 운영

**제일학원** — RPA Dev  
_2020.06. – 2021.03._

- Python과 OpenCV로 PDF 이미지 → 한글 문서 변환기 개발
- 수학 강의 영상 타임라인 자동 생성기 개발
- 한글 매크로 + Python으로 교재 QR 코드 자동 삽입 솔루션 개발
- 알고리즘 기반 자동 수학 문제 생성기 개발

---

## 사이드 프로젝트 & 커뮤니티

![](assets/img/about/aaa.png){: .shadow }
_백준 온라인 저지에 출제한 알고리즘 문제 삽화_

**백준 온라인 저지** ["생각하는 프로그래밍 대회" 4회·5회](https://www.acmicpc.net/category/detail/2793)에 총 **5문제**를 출제했습니다. UCPC, SCPC, ICPC 2020 Korea 등 알고리즘 경진대회에도 참가했습니다.

**비대면 해결사** · 2020  
코로나19로 비대면 수업이 급증하던 시기, Python + Selenium으로 사이버 강의 관리 프로그램을 개발해 '에브리타임'에 배포했습니다. **500회 이상 다운로드**를 기록했습니다.

---

## 기술 스택

| 분류 | 스택 |
| --- | --- |
| **언어** | Java · Python · C++ |
| **백엔드** | Spring · Django |
| **데이터베이스** | MySQL · PostgreSQL |
| **DevOps / 인프라** | AWS · Docker · Kubernetes (k3s) · Cloudflare Tunnel · Ubuntu · WSL |
| **기타** | RESTful API · Selenium · OpenCV |

---

## 자격증

![](assets/img/about/uipath.png){: width="220" .normal .shadow }

**UIARD — UiPath Advanced RPA Developer Certification**  
UiPath · 2022.12.01.  
[인증서 확인 →](https://credentials.uipath.com/eccb5bc6-083e-49d8-b497-e7fb8086331f#acc.NY6xsWK8)

---

## Contact

- **GitHub** — [@Sunkist18](https://github.com/Sunkist18)
- **Email** — [chaeminu0711@gmail.com](mailto:chaeminu0711@gmail.com)
