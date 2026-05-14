package com.eattogether.security.jwt;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Date;
import java.util.List;

@Slf4j
@Component
public class JwtTokenProvider {

    private final SecretKey key;
    private final long accessTokenExpire;
    private final long refreshTokenExpire;

    public JwtTokenProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-token-expire}") long accessTokenExpire,
            @Value("${jwt.refresh-token-expire}") long refreshTokenExpire) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenExpire = accessTokenExpire;
        this.refreshTokenExpire = refreshTokenExpire;
    }

    public TokenDto generateTokens(Long userId, String role) {
        long now = System.currentTimeMillis();

        String accessToken = Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("role", role)
                .issuedAt(new Date(now))
                .expiration(new Date(now + accessTokenExpire))
                .signWith(key)
                .compact();

        String refreshToken = Jwts.builder()
                .subject(String.valueOf(userId))
                .issuedAt(new Date(now))
                .expiration(new Date(now + refreshTokenExpire))
                .signWith(key)
                .compact();

        return TokenDto.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .accessTokenExpireIn(accessTokenExpire)
                .build();
    }

    public Authentication getAuthentication(String token) {
        Claims claims = parseClaims(token);
        String role = claims.get("role", String.class);
        List<SimpleGrantedAuthority> authorities =
                Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role));
        User principal = new User(claims.getSubject(), "", authorities);
        return new UsernamePasswordAuthenticationToken(principal, token, authorities);
    }

    public Long getUserId(String token) {
        return Long.parseLong(parseClaims(token).getSubject());
    }

    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (ExpiredJwtException e) {
            log.debug("Expired JWT token");
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT token: {}", e.getMessage());
        }
        return false;
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
