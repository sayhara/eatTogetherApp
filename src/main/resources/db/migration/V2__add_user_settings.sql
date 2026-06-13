-- 알림 수신 여부 컬럼 추가
ALTER TABLE users ADD COLUMN notification_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- 닉네임 중복 방지 유니크 제약 (기존 데이터 중복 있을 경우 먼저 정리 필요)
ALTER TABLE users ADD CONSTRAINT uq_users_nickname UNIQUE (nickname);
