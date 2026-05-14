package com.eattogether.config;

import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RateLimit {
    int maxRequests();
    int windowSeconds();
    String key() default "";
}
