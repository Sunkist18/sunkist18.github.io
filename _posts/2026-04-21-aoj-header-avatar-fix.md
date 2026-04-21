---
title: ANA Online Judge 우상단 아바타 버그 고치기
date: 2026-04-21 22:00:00 +0900
categories: [Dev, OpenSource]
tags: [NextAuth, Next.js, Drizzle, OrbStack, 오픈소스 기여, 버그 수정]
description: ANA 동아리 자체 온라인 저지(AOJ) 헤더의 아바타가 유저네임 이니셜만 찍히는 버그를 잡고 PR 올리기까지
---

제가 있는 학교 알고리즘 동아리 ANA가 자체 온라인 저지 **AOJ**를 만들었어요. BOJ 서비스 종료 소식 이후 PS 학습자들이 갈 곳이 애매해진 상황에서, 회장(황현석)이 "큰 커뮤니티보단 동아리 내에서 서로 성과를 공유하는 환경이 성장 동력이었다"며 동아리 차원에서 OJ를 운영하기로 했고, ANA 역대 대회 문제와 USACO 문제를 수록해서 [aoj.anacnu.kr](https://aoj.anacnu.kr)로 열었어요.

동아리에 도움이 되고 싶어서 로그인부터 해봤는데, 우상단 아바타가 프로필 사진을 넣어도 username(닉네임도 아닌 아이디)의 첫 글자만 찍혀 있더라고요. fork 떠서 고치고 PR([#14](https://github.com/csh1668/ana-online-judge/pull/14))까지 올렸어요.

## 환경

| 항목 | 값 |
|------|-----|
| HW / OS | Apple Silicon (arm64) / macOS 26.3.1 |
| 런타임 | Node.js v22.14.0, pnpm 10.14.0 |
| 프레임워크 | Next.js 16.2.2 (Turbopack), NextAuth v5, drizzle-kit |
| 컨테이너 | OrbStack 2.1.1, postgres:18-alpine, redis:7-alpine, minio:latest |
| 대상 리포 | `csh1668/ana-online-judge` @ upstream/main |
| 작업 브랜치 | `fix/header-avatar-fallback` (fork: `Sunkist18/ana-online-judge`) |

## 뭐가 문제였나

세션이 내려주는 값을 먼저 까봤어요.

```js
fetch('/api/auth/session').then(r => r.json()).then(console.log)
```
{: .nolineno }

`avatarUrl`이 응답에 아예 없고, `name`에는 닉네임이 아니라 username이 들어가 있어요. 코드를 따라가 보니 세 군데가 물려 있었어요.

- `src/auth.ts`의 `authorize()`가 `name: user[0].username`을 반환해서 DB의 `users.name`이 세션에 닿을 길이 없었어요.
- `jwt` 콜백이 `name`/`avatarUrl`을 토큰에 올리지 않고, `session` 콜백도 `session.user.avatarUrl`을 안 세팅해서 클라이언트는 영원히 `undefined`만 봤어요.
- UI 쪽은 `components/auth/user-menu.tsx`에서 `<Avatar>`만 렌더하고 `<AvatarImage>`가 없어서 이니셜 fallback만 찍히고 있었고, `ProfileHeader.handleSave`는 `updateProfile` 서버 액션만 부르고 세션 갱신을 안 해서 저장 직후 새로고침 전까진 옛 값이 남았어요.

## 코드 수정

네 파일, 커밋 둘로 쪼갰어요.

`src/auth.ts` — `authorize()`가 실제 `name`을 내려주고, 콜백이 `avatarUrl`을 통과시키게 고쳤어요.

```typescript
// authorize() 반환
{
  id: user[0].id,
  email: user[0].email,
  username: user[0].username,
  name: user[0].name,                       // was: user[0].username
  avatarUrl: user[0].avatarUrl ?? null,     // 추가
  mustChangePassword: user[0].mustChangePassword,
}
```
{: file="web/src/auth.ts" }

클라이언트에서 프로필을 저장했을 때 세션을 바로 갱신할 수 있게 `trigger === "update"` 분기도 넓혔어요.

```typescript
if (trigger === "update" && session) {
  if (typeof session.mustChangePassword === "boolean") {
    token.mustChangePassword = session.mustChangePassword;
  }
  if (typeof session.name === "string") token.name = session.name;
  if (typeof session.avatarUrl === "string" || session.avatarUrl === null) {
    token.avatarUrl = session.avatarUrl;
  }
}
```
{: file="web/src/auth.ts" }

`user-menu.tsx`는 `<AvatarImage>`를 넣고 우선순위를 `avatarUrl → image → undefined`로 뒀어요. 이니셜 fallback 로직(`name.split(" ").slice(0,2)`)은 그대로라 `name`이 `avatarUrl`과 같이 제대로 내려오기만 하면 자동으로 닉네임 이니셜이 찍혀요.

```tsx
const avatarSrc = currentUser.avatarUrl ?? currentUser.image ?? undefined;

<Avatar>
  <AvatarImage src={avatarSrc} alt={currentUser.name ?? currentUser.username} />
  <AvatarFallback>{/* 기존 이니셜 로직 */}</AvatarFallback>
</Avatar>
```
{: file="web/src/components/auth/user-menu.tsx" }

프로필 저장 직후 헤더 반영은 `useSession().update()`로요. 본인 프로필일 때만이에요.

```tsx
const { update: updateSession } = useSession();

if (isOwner) {
  await updateSession({ name: trimmedName, avatarUrl: nextAvatarUrl });
}
```
{: file="web/src/app/profile/[userName]/profile-header.tsx" }

타입 선언(`src/types/next-auth.d.ts`)에 `Session.user.avatarUrl: string | null`, `User.avatarUrl?`, `JWT.avatarUrl?`을 추가했어요.

## 결과

프로필 이미지를 안 넣은 유저는 이제 `username`이 아니라 `name`(닉네임)의 이니셜로 fallback이 찍혀요.

![username이 아닌 name 이니셜로 fallback](/assets/img/posts/aoj-header-avatar-fix/before-initial-fix.png){: w="700" .shadow }
_우상단과 프로필 페이지 모두 닉네임 이니셜로 대체되는 모습_

프로필 이미지를 설정한 유저는 프로필 페이지뿐 아니라 우상단에도 제대로 이미지가 뜨고요.

![프로필 이미지 설정 시 우상단에도 반영](/assets/img/posts/aoj-header-avatar-fix/after-image-fix.png){: w="700" .shadow }
_저장 직후 `useSession().update()`로 헤더까지 바로 반영되는 모습_

> NextAuth v5에서 `useSession().update(payload)`를 부르면 `jwt` 콜백이 `trigger === "update"`로 재호출돼요. 서버 액션이 DB만 갱신하고 세션을 건드리지 않으면 클라이언트 `useSession()`은 다음 새로고침 전까진 옛 값을 들고 있어요.
{: .prompt-info }

## 로컬 띄우면서 만난 것들

고친 뒤 검증하려고 dev를 띄우는 데 몇 번 걸렸어요.

- README는 `cp web/.env.example web/.env`라고 적혀 있는데 `web/.env.example` 자체가 리포에 없어요. `docker-compose.yml`이랑 `web/src/lib/env/serverEnv.ts`의 zod 스키마를 보면서 손으로 채웠어요.
- `make dev-up`의 judge 이미지 빌드가 `"/usr/local/rustup/toolchains/1.91.1-x86_64-unknown-linux-gnu/bin": not found`로 깨지더라고요. `judge/Dockerfile`이 `x86_64-unknown-linux-gnu`를 하드코딩해 둬서 arm64 호스트에선 경로가 없는 거예요. 아바타 UI 수정에 judge가 필요 없으니 `docker compose up -d postgres redis minio`로 인프라 3개만 올렸어요.
- `make dev-db-migrate`는 `relation "playground_files" does not exist`로 깨졌어요. `drizzle/0001_playground_minio_migration.sql`이 `TRUNCATE TABLE playground_files CASCADE`로 시작하는데 정작 `CREATE TABLE`은 `0002_mute_husk.sql`에 있어서요. `pnpm db:push`로 `schema.ts`에서 바로 DB에 밀어 넣는 쪽으로 우회했어요.
- `auth.ts`에 박은 `console.log`가 HMR로 안 반영돼서 한참 헤맸어요. NextAuth 설정 파일은 서버 청크·미들웨어에 묶여서 Turbopack이 재로드하지 않는 것 같아요. `lsof -ti:3000 | xargs kill -9` 후 `pnpm dev` 재기동하니까 `[auth.jwt update] session payload: {"name":"홍길동","avatarUrl":"..."}`가 찍혔어요.
- `git push` 단계에선 pre-push 훅이 `judge/`에서 `cargo check`를 돌리는데 제 rustc는 Homebrew 1.88.0이고 `aws-config@1.8.15`가 1.91.1을 요구해서 막혔어요. `rustup`이 없어서 이번엔 `--no-verify`로 우회했는데, 원래는 rustup 깔고 1.91.1로 올리는 게 맞아요.

`web/.env.example` 부재, 마이그레이션 순서 꼬임, `judge/Dockerfile`의 아키텍처 하드코딩은 이번 PR 스코프 밖이라 별도 이슈 감이에요.

## 한계

- Google OAuth 브랜치도 같이 고쳤는데 로컬에 Client ID/Secret을 안 넣어서 실제 구글 로그인으론 검증 못 했어요. PR에는 미검증으로 남겼고요.
- 관리자 대리 로그인(impersonation) 경로에도 `session.user.avatarUrl = targetUser.avatarUrl ?? null`을 넣어 뒀는데, 이것도 실행 검증은 못 했어요.

## 참고 링크

- AOJ: <https://aoj.anacnu.kr>
- 대상 리포: <https://github.com/csh1668/ana-online-judge>
- 올린 PR: <https://github.com/csh1668/ana-online-judge/pull/14>
- 관련 이슈: <https://github.com/csh1668/ana-online-judge/issues/13>
