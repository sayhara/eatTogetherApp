-- ============================================================
-- V4 소셜 로그인 계정 연동을 위한 provider 식별 정보 분리
-- ============================================================

CREATE TABLE user_oauth_connections (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT       NOT NULL REFERENCES users(id),
    provider    VARCHAR(50)  NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    created_at  TIMESTAMP,
    CONSTRAINT uq_user_oauth_connections UNIQUE (provider, provider_id)
);

-- 기존 사용자의 provider/provider_id를 새 테이블로 백필
INSERT INTO user_oauth_connections (user_id, provider, provider_id, created_at)
SELECT id, provider, provider_id, COALESCE(created_at, now())
FROM users;
