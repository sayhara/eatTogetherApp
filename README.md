# 🍽️ 잇투게더 (EatTogether)

> 근처의 사람들과 함께 밥을 먹는 소셜 다이닝 앱

---

## 소개

혼밥이 싫을 때, 근처에서 같이 밥 먹을 사람을 찾아주는 모임 매칭 서비스입니다.  
모임을 만들거나 신청하고, 채팅으로 약속을 잡고, 식사 후 리뷰를 남깁니다.

---

## 주요 기능

- **소셜 로그인** — 카카오 / 구글 / 네이버
- **근처 모임 탐색** — GPS 기반 지도 + 리스트
- **모임 생성 및 참여** — 식당, 시간, 인원 설정 / 참여 신청 및 승인
- **실시간 채팅** — 모임별 채팅방 (WebSocket/STOMP)
- **리뷰** — 모임 완료 후 참여자 별점 평가
- **푸시 알림** — 참여 신청, 승인/거절, 채팅 메시지 (FCM)

---

## 기술 스택

| 구분 | 기술 |
|---|---|
| Frontend | Flutter, Riverpod, GoRouter, Dio |
| Backend | Spring Boot 3, JPA, PostgreSQL |
| 실시간 | WebSocket (STOMP), Redis Pub/Sub |
| 지도 | Naver Maps SDK |
| 알림 | Firebase Cloud Messaging |
| 인증 | OAuth2 (소셜 로그인), JWT |

---

## 스크린샷

<!-- 추후 추가 -->

---

## 실행 방법

### 서버
```bash
cd eat-together
.\gradlew.bat bootRun
```

### 앱 (에뮬레이터)
```bash
adb reverse tcp:8080 tcp:8080
cd frontend
flutter run
```

---

## 환경 변수

서버 실행 전 아래 환경 변수가 필요합니다.

| 변수명 | 설명 |
|---|---|
| `KAKAO_CLIENT_ID` | 카카오 OAuth 앱 키 |
| `KAKAO_CLIENT_SECRET` | 카카오 시크릿 |
| `GOOGLE_CLIENT_ID` | 구글 OAuth 클라이언트 ID |
| `GOOGLE_CLIENT_SECRET` | 구글 시크릿 |
| `NAVER_CLIENT_ID` | 네이버 OAuth 클라이언트 ID |
| `NAVER_CLIENT_SECRET` | 네이버 시크릿 |
| `JWT_SECRET` | JWT 서명 키 (32자 이상) |
| `DB_HOST` / `DB_NAME` | PostgreSQL 접속 정보 |
| `REDIS_HOST` | Redis 접속 정보 |

---

## 프로젝트 구조

```
eat-together/
├── src/                        # Spring Boot 서버
│   └── main/java/com/eattogether/
│       ├── auth/               # 인증 (JWT, OAuth2)
│       ├── gathering/          # 모임
│       ├── chat/               # 채팅
│       ├── review/             # 리뷰
│       ├── user/               # 사용자
│       └── fcm/                # 푸시 알림
└── frontend/                   # Flutter 앱
    └── lib/
        ├── core/               # 라우터, 공통 설정
        └── features/
            ├── auth/           # 로그인
            ├── home/           # 홈 (지도, 탐색, 목록)
            ├── gathering/      # 모임 상세/생성/수정
            ├── chat/           # 채팅
            ├── review/         # 리뷰
            └── mypage/         # 마이페이지
```

---

## 개발자

| 역할 | 이름 |
|---|---|
| 기획 / 풀스택 개발 | sayhara |
