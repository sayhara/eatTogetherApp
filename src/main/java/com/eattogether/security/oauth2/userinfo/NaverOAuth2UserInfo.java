package com.eattogether.security.oauth2.userinfo;

import java.util.Map;

public class NaverOAuth2UserInfo extends OAuth2UserInfo {

    @SuppressWarnings("unchecked")
    public NaverOAuth2UserInfo(Map<String, Object> attributes) {
        // 네이버는 응답이 { "response": { "id": ..., "email": ... } } 구조
        super((Map<String, Object>) attributes.get("response"));
    }

    @Override
    public String getProviderId() {
        return (String) attributes.get("id");
    }

    @Override
    public String getEmail() {
        return (String) attributes.get("email");
    }

    @Override
    public String getName() {
        return (String) attributes.get("name");
    }

    @Override
    public String getProfileImageUrl() {
        return (String) attributes.get("profile_image");
    }
}
