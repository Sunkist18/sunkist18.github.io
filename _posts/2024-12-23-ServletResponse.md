---
title: "HttpServletResponse"
date: 2024-12-23 01:33:00 +0900
categories: [Study, Spring]
tags: [Spring, Servlet, HTTP, Response]
description: 서블릿 HTTP 응답 정리 📌
---

# HttpServletResponse

---

## 1. HttpServletResponse - 기본 사용법

### 주요 내용
- **HTTP Status Code** 지정  
- **Header** 세팅  
- **쿠키** 사용법  
- **리다이렉트** 처리 (302 코드와 Location 헤더)  

### 핵심 포인트
- `setStatus()`, `setHeader()` 등을 통해 응답 상태 및 헤더를 손쉽게 지정  
- `addCookie()` 등을 통해 쿠키 생성 가능  
- `sendRedirect()` 메서드로 편리하게 리다이렉트 처리  

> **Tip**: 숫자 코드(`200`, `404`) 대신 상수(`HttpServletResponse.SC_OK`)를 사용하면 의미가 명확해집니다.
{: .prompt-tip }

---

## 2. HTTP 응답 데이터 - 단순 텍스트, HTML

### 주요 내용
- **단순 텍스트** 응답: `text/plain` MIME 타입 사용  
- **HTML** 응답: `text/html` MIME 타입 지정 후 HTML을 작성해서 반환  

### 예시 코드 (HTML 응답)

```java
@WebServlet(name = "responseHtmlServlet", urlPatterns = "/response-html")
public class ResponseHtmlServlet extends HttpServlet {
    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // MIME 타입, 인코딩 설정
        response.setContentType("text/html");
        response.setCharacterEncoding("utf-8");

        PrintWriter writer = response.getWriter();
        writer.println("<html>");
        writer.println("<body>");
        writer.println("<h1>HTML 응답 테스트</h1>");
        writer.println("</body>");
        writer.println("</html>");
    }
}
```

- 브라우저는 `text/html`로 지정된 응답을 **HTML 문서**로 인식  
- 동적으로 HTML을 생성해 클라이언트에 보내는 방식 구현 가능  

---

## 3. HTTP 응답 데이터 - API JSON

### 주요 내용
- **HTTP API** 혹은 **RESTful API** 구현 시 주로 활용  
- 응답 타입을 `application/json`으로 지정  
- 자바 객체 -> JSON 변환 시 `ObjectMapper` 활용  

### 예시 코드 (JSON 응답)

```java
@WebServlet(name = "responseJsonServlet", urlPatterns = "/response-json")
public class ResponseJsonServlet extends HttpServlet {
    
    private ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void service(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 응답 Content-Type 지정
        response.setContentType("application/json");
        response.setCharacterEncoding("utf-8");

        // 자바 객체 생성
        HelloData helloData = new HelloData();
        helloData.setUsername("김");
        helloData.setAge(20);

        // 자바 객체 -> JSON 문자열
        String result = objectMapper.writeValueAsString(helloData);

        // JSON 문자열을 응답 바디에 출력
        response.getWriter().write(result);
    }
}
```

- `application/json`은 UTF-8을 기본으로 사용  
- 다른 라이브러리(Gson 등)도 사용 가능  
- 실제 서비스에서는 DTO, VO 등을 JSON 변환해 응답  

---

## 마무리

핵심 요점은 **HttpServletResponse**를 통해 **상태 코드**, **헤더**, **바디**를 자유자재로 조정하며, 텍스트·HTML·JSON 등의 **다양한 응답**을 편리하게 구현할 수 있다는 것입니다.  
앞으로 스프링 프레임워크나 기타 기술과 결합해 훨씬 효율적인 방법들을 확인하게 될 것입니다. 

감사합니다!
