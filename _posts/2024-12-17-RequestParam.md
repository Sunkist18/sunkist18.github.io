---
title: "GET 쿼리와 Form 전송"
date: 2024-12-17 05:55:00 +0900
categories: [Study, Spring]
tags: [Spring, Servlet, HTTP, Request Parameter, Form Data]
description: HTTP 요청 Request 파라미터 데이터 처리 기초 😊
---

# Request 파라미터 집중 분석

이번 포스팅에서는 HTTP Request 파라미터를 깊이 있게 살펴보겠습니다.  
GET 쿼리 파라미터와 POST Form 전송을 중심으로, **입력 데이터 처리**의 핵심 내용을 정리해보았습니다. 😊

---

## 학습 내용 순서

- **1**: `RequestHeaderServlet` 학습
- **2**: 요청 데이터 3가지 유형 (쿼리 파라미터, HTML Form, API Body) 개요
- **3**: GET 방식 Query Parameter 사용법 (`request.getParameter()`)
- **4**: POST-Form 전송(`application/x-www-form-urlencoded`) 구조와 학습

---

## 순서 배치의 이유

1. Request Header 출력·분석 학습을 통해 HTTP 요청 정보의 세부 구조를 먼저 이해합니다.  
2. 클라이언트에서 서버로 데이터를 전송하는 **3가지 핵심 방식**(쿼리 파라미터, HTML Form, API Body)을 빠르게 파악합니다.  
3. **GET 쿼리 파라미터**와 **POST Form 데이터**를 연달아 살펴봄으로써 **Request 파라미터 처리**를 체계적으로 정리합니다.  

---

## RequestHeaderServlet 학습

HTTP 요청 메시지의 가장 첫 부분인 **Start-Line**(메서드, URL, 프로토콜)과 **Header** 정보를 어떻게 확인하는지 보여주는 학습입니다.  
Servlet에서 `HttpServletRequest` 객체를 활용해 다음 정보를 출력해볼 수 있습니다.

- **Start-Line**: `getMethod()`, `getProtocol()`, `getScheme()`, `getRequestURL()` 등
- **Header 전체**: `request.getHeaderNames()`, `request.getHeaders()`
- **편의 기능**: `request.getCookies()`, `request.getLocales()`, `request.getServerName()` 등

이를 통해 **브라우저가 전송하는 상세 헤더 정보**(Host, Connection, Accept 등)와 **쿠키, 로케일 정보** 등을 모두 확인할 수 있습니다.

> 직접 위 함수들을 실행해보며, HTTP 메시지를 서블릿이 어떻게 해석하고 파싱하는지 이해할 수 있습니다.  
{: .prompt-info }

> 로컬에서 테스트 시 IPv6 정보가 나올 수 있는데, IPv4 정보를 보고 싶다면 VM 옵션에 아래를 추가하세요.  
>   `-Djava.net.preferIPv4Stack=true`   
{: .prompt-warning }

---

## 요청 데이터 3가지 유형

서버 측에서 **클라이언트가 전송하는 요청 데이터**를 크게 세 가지 방식으로 분류합니다.

1. **GET 쿼리 파라미터**  
   - URL 끝에 `?key=value` 형태로 붙는 파라미터  
   - 검색, 필터, 페이징 같은 기능 구현 시 주로 사용  
   - 요청 바디가 없으므로 `Content-Type`이 없음

2. **POST-HTML Form**  
   - 회원가입, 로그인 같은 **HTML 폼 전송** 시 사용  
   - 메시지 바디에 폼 데이터를 담으며 `Content-Type: application/x-www-form-urlencoded`로 전송  
   - `request.getParameter()` 메서드로 GET 쿼리와 동일하게 조회 가능

3. **API 요청 바디**  
   - JSON, XML, 텍스트 등 다양한 형식으로 메시지 바디에 직접 전송  
   - REST API 통신에서 주로 사용 (POST, PUT, PATCH 등)  
   - 형식에 따라 `Content-Type`이 `application/json`, `application/xml` 등으로 지정됨

> 이 3가지 유형을 명확히 구분해두면, HTTP 프로토콜 기반의 **데이터 전송** 방식을 헷갈리지 않고 쉽게 이해할 수 있습니다.  
{: .prompt-tip }

---

## GET 방식 Query Parameter 사용법

가장 대표적인 예로, URL 뒤에 `?userName=hello&age=20` 같은 형식으로 데이터를 전송하는 방식입니다.

1. **파라미터 전체 조회**  
   ```java
   Enumeration<String> parameterNames = request.getParameterNames();
   while(parameterNames.hasMoreElements()) {
       String paramName = parameterNames.nextElement();
       String paramValue = request.getParameter(paramName);
       System.out.println("파라미터 이름=" + paramName + ", 값=" + paramValue);
   }
   ```

2. **단일 파라미터 조회**  
   ```java
   String userName = request.getParameter("userName");
   String age      = request.getParameter("age");
   System.out.println("userName = " + userName);
   System.out.println("age = " + age);
   ```

3. **복수 파라미터 조회**  
   - 같은 이름의 파라미터가 여러 개 있을 경우, `request.getParameterValues()`를 사용  
   - 예: `?userName=hello&userName=hello2`

GET 쿼리 파라미터의 **핵심**은 **URL에 데이터가 노출**된다는 점과, **요청 바디**를 사용하지 않는다는 점입니다.  
검색, 필터, 페이징에서 자주 쓰이며, **서버에서는 `request.getParameter()`** 한 가지 메서드로 간단하게 처리 가능합니다.

---

## POST Form 전송

`application/x-www-form-urlencoded` 형식으로 **HTML Form**을 전송하는 경우입니다. 예를 들어, 회원가입 페이지에서 다음과 같은 폼을 제출한다고 합시다:

<form>
  <input type="text" name="userName" value="최민우" />
  <input type="text" name="age" value="24" />
  <button type="submit">전송</button>
</form>
```html
<!-- 위는 예시 Form 입니다 -->
<form action="/request-param" method="post">
  <input type="text" name="userName" value="kim" />
  <input type="text" name="age" value="20" />
  <button type="submit">전송</button>
</form>
```



- 브라우저가 **form 데이터**를 메시지 바디에 실어 `POST` 요청을 생성  
- 서버는 `request.getParameter("userName")`, `request.getParameter("age")` 같은 메서드로 값 조회  
- GET 쿼리처럼 **Key=Value** 구조지만, 이 경우 **URL 대신 바디에** 실린다는 차이가 있음  
- `Content-Type` 헤더가 `application/x-www-form-urlencoded`로 지정됨

결과적으로 **GET 쿼리 파라미터**와 **POST Form 전송**은 서버 입장에서 동일한 메서드(`getParameter()`)로 처리할 수 있다는 장점이 있습니다.  
단, POST 전송 시에는 반드시 **Content-Type**을 통해 바디 데이터 형식을 지정해야 합니다.


> 웹 브라우저 캐시나 서버 재시작 이슈로 이전 결과가 보일 수 있습니다.  
> 이 경우 **새로 고침**을 해주시거나 **서버를 재시작**하면 됩니다.  
{: .prompt-warning }

---

# 결론

위 내용을 정리하면, **클라이언트가 서버로 전송하는 데이터**는 크게 세 가지 방식(쿼리 파라미터, HTML Form, API Body)으로 나뉘며, 그중에서 GET과 POST Form은 모두 `request.getParameter()`로 처리할 수 있다는 사실을 알 수 있습니다.

**다음 포스팅**에서는 API 형태로 데이터를 전송할 때, 즉 **JSON**이나 **XML**을 바디에 담아 보내는 방식을 어떻게 처리하는지 살펴보겠습니다. 감사합니다. 😊
