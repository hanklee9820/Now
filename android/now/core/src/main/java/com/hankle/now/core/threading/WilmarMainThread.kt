package com.hankle.now.core.threading

import android.os.Handler
import android.os.Looper

object WilmarMainThread {
    private val handler = Handler(Looper.getMainLooper())

    fun isMainThread(): Boolean = Looper.myLooper() == Looper.getMainLooper()

    fun beginInvokeOnMainThread(action: () -> Unit) {
        if (isMainThread()) {
            action()
        } else {
            handler.post(action)
        }
    }
}

