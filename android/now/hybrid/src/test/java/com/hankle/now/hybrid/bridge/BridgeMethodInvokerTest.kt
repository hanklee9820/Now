package com.hankle.now.hybrid.bridge

import com.hankle.now.hybrid.jsbridge.attribute.JsCallback
import com.hankle.now.hybrid.jsbridge.attribute.JsInterface
import com.hankle.now.hybrid.jsbridge.attribute.JsNativeClass
import com.hankle.now.hybrid.jsbridge.attribute.JsParam
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BridgeMethodInvokerTest {

    @Test
    fun `dispatches annotated methods and serializes return values`() {
        val scripts = mutableListOf<String>()
        val invoker = BridgeMethodInvoker(listOf(TestHook())) { script ->
            scripts += script
        }

        val consumed = invoker.dispatch(
            BridgeInvocationRequest(
                methodName = "doubleValue",
                paramData = "4",
                callbackId = "window.callback",
                oldVersion = false,
            ),
        )

        assertTrue(consumed)
        assertEquals(1, scripts.size)
        assertTrue(scripts.single().contains("window.callback("))
        assertTrue(scripts.single().contains(""""code":200"""))
        assertTrue(scripts.single().contains(""""data":8"""))
    }

    @Test
    fun `supports callback parameters`() {
        val scripts = mutableListOf<String>()
        val invoker = BridgeMethodInvoker(listOf(TestHook())) { script ->
            scripts += script
        }

        val consumed = invoker.dispatch(
            BridgeInvocationRequest(
                methodName = "emitWithCallback",
                paramData = "5",
                callbackId = "window.callback",
                oldVersion = false,
            ),
        )

        assertTrue(consumed)
        assertEquals(1, scripts.size)
        assertTrue(scripts.single().contains(""""data":15"""))
    }

    @JsNativeClass
    class TestHook {
        @JsInterface("doubleValue")
        fun doubleValue(@JsParam value: Int): Int = value * 2

        @JsInterface("emitWithCallback")
        fun emitWithCallback(
            @JsParam value: Int,
            @JsCallback callback: (Any?) -> Unit,
        ) {
            callback(value * 3)
        }
    }
}
