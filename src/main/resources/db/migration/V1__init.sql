-- ============================================================
-- V1 초기 스키마
-- ============================================================

CREATE TABLE users (
    id               BIGSERIAL PRIMARY KEY,
    nickname         VARCHAR(255) NOT NULL,
    email            VARCHAR(255),
    profile_image_url VARCHAR(255),
    provider         VARCHAR(50)  NOT NULL,
    provider_id      VARCHAR(255) NOT NULL,
    role             VARCHAR(50)  NOT NULL,
    latitude         DOUBLE PRECISION,
    longitude        DOUBLE PRECISION,
    created_at       TIMESTAMP,
    updated_at       TIMESTAMP,
    CONSTRAINT uq_users_provider UNIQUE (provider, provider_id)
);

CREATE TABLE gatherings (
    id                 BIGSERIAL PRIMARY KEY,
    host_id            BIGINT       NOT NULL REFERENCES users(id),
    title              VARCHAR(50)  NOT NULL,
    description        VARCHAR(200),
    restaurant_name    VARCHAR(255) NOT NULL,
    latitude           DOUBLE PRECISION NOT NULL,
    longitude          DOUBLE PRECISION NOT NULL,
    address            VARCHAR(255),
    category           VARCHAR(50),
    max_participants   INTEGER      NOT NULL,
    meal_time          TIMESTAMP    NOT NULL,
    status             VARCHAR(50)  NOT NULL DEFAULT 'OPEN',
    created_at         TIMESTAMP,
    updated_at         TIMESTAMP
);

CREATE TABLE gathering_participants (
    id           BIGSERIAL PRIMARY KEY,
    gathering_id BIGINT NOT NULL REFERENCES gatherings(id),
    user_id      BIGINT NOT NULL REFERENCES users(id),
    status       VARCHAR(20) NOT NULL DEFAULT 'APPROVED',
    joined_at    TIMESTAMP,
    CONSTRAINT uq_gathering_participants UNIQUE (gathering_id, user_id)
);

CREATE TABLE reviews (
    id           BIGSERIAL PRIMARY KEY,
    gathering_id BIGINT   NOT NULL,
    reviewer_id  BIGINT   NOT NULL REFERENCES users(id),
    reviewee_id  BIGINT   NOT NULL REFERENCES users(id),
    rating       INTEGER  NOT NULL,
    comment      VARCHAR(200),
    created_at   TIMESTAMP,
    CONSTRAINT uq_reviews UNIQUE (gathering_id, reviewer_id, reviewee_id)
);

CREATE TABLE chat_messages (
    id           BIGSERIAL PRIMARY KEY,
    gathering_id BIGINT       NOT NULL,
    sender_id    BIGINT       REFERENCES users(id),
    content      VARCHAR(500) NOT NULL,
    type         VARCHAR(50)  NOT NULL,
    created_at   TIMESTAMP
);

CREATE INDEX idx_chat_gathering_id ON chat_messages (gathering_id, created_at);

CREATE TABLE chat_read_status (
    id           BIGSERIAL PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    gathering_id BIGINT NOT NULL,
    last_read_at TIMESTAMP,
    CONSTRAINT uq_chat_read_status UNIQUE (user_id, gathering_id)
);

CREATE TABLE fcm_tokens (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL,
    token      VARCHAR(255) NOT NULL UNIQUE,
    device_id  VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP,
    CONSTRAINT uq_fcm_tokens UNIQUE (user_id, device_id)
);

CREATE TABLE reports (
    id          BIGSERIAL PRIMARY KEY,
    reporter_id BIGINT       NOT NULL,
    type        VARCHAR(50)  NOT NULL,
    target_id   BIGINT       NOT NULL,
    reason      VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    status      VARCHAR(50)  NOT NULL DEFAULT 'PENDING',
    created_at  TIMESTAMP,
    CONSTRAINT uq_reports UNIQUE (reporter_id, type, target_id)
);

CREATE TABLE user_blocks (
    id         BIGSERIAL PRIMARY KEY,
    blocker_id BIGINT NOT NULL,
    blocked_id BIGINT NOT NULL,
    created_at TIMESTAMP,
    CONSTRAINT uq_user_blocks UNIQUE (blocker_id, blocked_id)
);
