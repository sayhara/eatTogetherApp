package com.eattogether.config;

import com.eattogether.common.exception.BusinessException;
import com.eattogether.common.exception.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

import java.time.Duration;

@Component
@RequiredArgsConstructor
public class RateLimitInterceptor implements HandlerInterceptor {

    private final RedisTemplate<String, String> redisTemplate;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (!(handler instanceof HandlerMethod method)) return true;

        RateLimit rateLimit = method.getMethodAnnotation(RateLimit.class);
        if (rateLimit == null) return true;

        String identifier = resolveIdentifier(request);
        String annotationKey = rateLimit.key().isBlank()
                ? method.getMethod().getDeclaringClass().getSimpleName() + "." + method.getMethod().getName()
                : rateLimit.key();
        String redisKey = "rl:" + identifier + ":" + annotationKey;

        Long count = redisTemplate.opsForValue().increment(redisKey);
        if (count != null && count == 1) {
            redisTemplate.expire(redisKey, Duration.ofSeconds(rateLimit.windowSeconds()));
        }
        if (count != null && count > rateLimit.maxRequests()) {
            throw new BusinessException(ErrorCode.RATE_LIMIT_EXCEEDED);
        }
        return true;
    }

    private String resolveIdentifier(HttpServletRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated() && !"anonymousUser".equals(auth.getPrincipal())) {
            return "user:" + auth.getName();
        }
        String ip = request.getHeader("X-Forwarded-For");
        return "ip:" + (ip != null ? ip.split(",")[0].trim() : request.getRemoteAddr());
    }
}
