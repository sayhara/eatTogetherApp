package com.eattogether.security.oauth2;

import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;

import java.util.Collection;
import java.util.Map;

@Getter
public class CustomOAuth2User extends DefaultOAuth2User {

    private final Long userId;
    private final String email;
    private final boolean isNewUser;
    private final boolean linkRequired;
    private final String linkToken;

    public CustomOAuth2User(Collection<? extends GrantedAuthority> authorities,
                            Map<String, Object> attributes,
                            String nameAttributeKey,
                            Long userId,
                            String email,
                            boolean isNewUser,
                            boolean linkRequired,
                            String linkToken) {
        super(authorities, attributes, nameAttributeKey);
        this.userId = userId;
        this.email = email;
        this.isNewUser = isNewUser;
        this.linkRequired = linkRequired;
        this.linkToken = linkToken;
    }
}
