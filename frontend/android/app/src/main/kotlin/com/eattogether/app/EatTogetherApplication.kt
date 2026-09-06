package com.eattogether.app

import android.app.Application
import android.os.Looper

class EatTogetherApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            // 릴리즈 빌드는 R8이 클래스 이름을 난독화(예: W2.g, c2.f)하므로
            // 스택트레이스의 클래스명으로는 더 이상 매칭할 수 없다. 예외 타입과
            // 메시지만으로 판별한다 — 이 메시지는 flutter_naver_map의 onAuthFailed
            // 중복 reply 버그에서만 발생하는 것으로 확인됨.
            val isNaverMapDoubleReplyBug = throwable is IllegalStateException &&
                throwable.message == "Reply already submitted"
            if (isNaverMapDoubleReplyBug && Looper.myLooper() == Looper.getMainLooper()) {
                android.util.Log.e(
                    "EatTogetherApplication",
                    "Suppressed known flutter_naver_map onAuthFailed double-reply crash; resuming main looper",
                    throwable
                )
                // The default handler would kill the process; since we're suppressing it,
                // Looper.loop() has already unwound past the crashing message, which would
                // otherwise leave the main thread alive but no longer pumping messages
                // (touch/UI hangs). Re-entering loop() keeps it dispatching.
                Looper.loop()
            } else {
                defaultHandler?.uncaughtException(thread, throwable)
            }
        }
    }
}
