package com.eattogether.app

import android.app.Application
import android.os.Looper

class EatTogetherApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            val isNaverMapDoubleReplyBug = throwable is IllegalStateException &&
                throwable.message == "Reply already submitted" &&
                throwable.stackTrace.any { it.className.contains("flutter_naver_map") }
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
