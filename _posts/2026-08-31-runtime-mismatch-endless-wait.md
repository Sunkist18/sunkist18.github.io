---
title: "How a runtime mismatch turned a quick failure into an endless wait"
date: 2026-08-31 00:20:00 +0900
categories: [Dev, DevOps]
tags: [opencode, Gradle, JDK, Java, 빌드, 무한대기]
---

> 해당 포스트 작성에서 AI의 개입은 오탈자 수정 정도뿐이다.  
> AI가 개입할수록 가독성이 떨어지는 것 같다.
{: .prompt-info }

opencode로 GPT와 Claude 모델을 함께 쓰고 있다.  
최근에 Claude Code에서 opencode로 옮겼는데 세팅할 게 많았다.  
세팅하고 테스트도 해보는 과정에서 AI가 무한대기하는 현상이 생겼다.

종료 신호를 못 받는 건지, Java 빌드를 할 때마다 무한대기가 일어났다.  
그 문제를 해결하느라 애를 좀 썼다.

사실 엄청 예전에도 비슷한 일이 있었다.  
한 3년 전, 처음 Cursor IDE를 썼을 때였던 것 같다.

그때도 Java를 컴파일하고 빌드하는 상황이었는데 무한대기가 일어나서 항상 중간에 인터럽트를 하고 진행했던 기억이 난다.  
그때는 그냥 그런가보다 하고 넘겼다.

이후로는 Java를 쓸 일이 없어서 이 문제도 없었다.  
최근에 한 프로젝트에서 Java를 다시 쓰게 됐다.  
하필 opencode로 바꾸면서 실험하던 참이라 원인을 알 수 없었다.  
opencode의 문제인지, Java의 문제인지.

그래서 로그를 뒤져서 원인을 찾았다.

Windows 환경에서 개발하고 있다.

## Gradle 8.11.1과 JDK 25의 불일치

찾아보니 Gradle과 JDK 버전의 호환성 문제였다.

Gradle 8.11.1 버전은 JDK 23까지만 실행 환경으로 지원하는데 실제 Gradle Wrapper 프로세스는 JDK 25로 실행되고 있었다.  
이 불일치 때문에 Gradle은 실패 메시지를 출력했지만  
그 아래 래퍼 프로세스가 종료되지 않았다.

로그에는 `BUILD FAILED exit code: 1` 문구가 계속 떠 있고  
프로세스도 exit code와 출력 종료 신호를 줬다.  
그런데 래퍼가 살아 있으니 자동화 시스템에서는 빌드가 끝난 걸로 안 쳤다.  
그대로 무한 대기다.

## JDK 버전 고정

원인만 알면 해결은 쉽다.  
Gradle 래퍼와 데몬이 지원하는 JDK 버전을 쓰도록 고정했다.  
수정해 보니 Gradle이 실패해도 정상적으로 종료됐다.
