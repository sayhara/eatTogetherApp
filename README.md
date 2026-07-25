# 🍽️ 잇투게더 (EatTogether)

> 근처의 사람들과 함께 밥을 먹는 소셜 다이닝 앱

🔗 **서비스 주소**: https://eattogetherapp.com
📱 **Play Store**: 내부 테스트 단계 (정식 출시 준비 중)

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
| 인증 | OAuth2 (카카오/네이버/구글 소셜 로그인), JWT |
| 인프라 | AWS EC2, Docker Compose, Nginx, Cloudflare(DNS/HTTPS) |
| CI/CD | GitHub Actions (main 브랜치 push 시 EC2 자동 배포) |

---

## 배포 인프라

```
사용자 → Cloudflare(HTTPS) → EC2:nginx(리버스 프록시) → Spring Boot(:8080)
                                              ├── PostgreSQL (컨테이너)
                                              └── Redis (컨테이너)
```

- **도메인**: `eattogetherapp.com` (Cloudflare 등록/DNS)
- **HTTPS**: Cloudflare Origin 인증서 (nginx에 적용, Cloudflare 프록시 통해 브라우저에는 정식 인증서로 보임)
- **배포 자동화**: `main` 브랜치에 push하면 GitHub Actions가 EC2에 SSH 접속해 `git pull` + `docker compose up -d --build` 실행
- **개인정보처리방침**: https://eattogetherapp.com/privacy
- **계정 삭제 안내**: https://eattogetherapp.com/delete-account

배포 관련 파일: [`Dockerfile`](Dockerfile), [`docker-compose.prod.yml`](docker-compose.prod.yml), [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)

---

## 스크린샷

<!-- 추후 추가 -->

---

## 로컬 실행 방법

### 서버
```bash
cd eat-together
cp .env.example .env   # 값 채우기
.\gradlew.bat bootRun
```

### 앱 (에뮬레이터)
```bash
adb reverse tcp:8080 tcp:8080
cd frontend
flutter run
```

### 프로덕션 방식 로컬 재현 (Docker)
```bash
cd eat-together
cp .env.example .env   # 값 채우기
docker compose -f docker-compose.prod.yml up -d --build
```

---

## 환경 변수

서버 실행 전 `.env`에 아래 값이 필요합니다 (`.env.example` 참고).

| 변수명 | 설명 |
|---|---|
| `KAKAO_CLIENT_ID` / `KAKAO_CLIENT_SECRET` | 카카오 OAuth REST API 키 / 시크릿 |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | 구글 OAuth 클라이언트 ID / 시크릿 |
| `NAVER_CLIENT_ID` / `NAVER_CLIENT_SECRET` | 네이버 OAuth 클라이언트 ID / 시크릿 |
| `JWT_SECRET` | JWT 서명 키 (32자 이상) |
| `DB_HOST` / `DB_NAME` / `DB_USER` / `DB_PASSWORD` | PostgreSQL 접속 정보 |
| `REDIS_HOST` / `REDIS_PORT` | Redis 접속 정보 |
| `OAUTH_REDIRECT_BASE_URL` | OAuth 콜백 base URL (로컬: `http://localhost:8080`, 운영: `https://eattogetherapp.com`) |
| `FIREBASE_CREDENTIALS_JSON` | Firebase 서비스 계정 JSON (한 줄로 압축, FCM 푸시용, 없으면 FCM만 비활성화) |

---

## Android 릴리즈 빌드 (Play Store 업로드용)

- **applicationId**: `com.sayhara.eattogether` (`com.eattogether.app`은 Play Store에 이미 등록되어 있어 사용 불가, 코드 패키지 `namespace`는 여전히 `com.eattogether.app`)
- **릴리즈 keystore**: 리포지토리에 포함되지 않음 (보안상 제외). `frontend/android/key.properties`도 gitignore 대상 — 새 작업 환경에서는 keystore 파일과 `key.properties`를 별도로 옮기고, `key.properties`의 `storeFile` 경로를 해당 환경에 맞게 수정해야 함
- **Firebase**: `google-services.json`도 `com.sayhara.eattogether` 기준으로 등록되어 있어야 함 (Firebase 콘솔에 해당 패키지명으로 Android 앱 추가 후 다운로드)
- **카카오 네이티브 SDK**: Kakao Developers 콘솔의 "네이티브 앱 키" 플랫폼 설정에 `com.sayhara.eattogether` 패키지명 + 릴리즈 keystore 기준 키 해시가 등록되어 있어야 함

```bash
cd frontend
flutter build appbundle --release
# 결과물: build/app/outputs/bundle/release/app-release.aab
```

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
