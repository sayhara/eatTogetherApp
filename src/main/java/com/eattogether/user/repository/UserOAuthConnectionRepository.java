package com.eattogether.user.repository;

import com.eattogether.user.domain.Provider;
import com.eattogether.user.domain.UserOAuthConnection;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserOAuthConnectionRepository extends JpaRepository<UserOAuthConnection, Long> {
    Optional<UserOAuthConnection> findByProviderAndProviderId(Provider provider, String providerId);
}
