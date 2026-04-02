package com.hankle.now.hybrid.jsbridge

data class NativeEventArgs(
    val eventName: String,
    val data: String,
)

data class NativeDataArgs(
    val callbackId: String = "",
    val params: String = "",
)

