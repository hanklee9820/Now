package com.hankle.now.hybrid.bridge

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BridgeInvocationRequestTest {

    @Test
    fun `parses structured bridge payloads`() {
        val request = BridgeInvocationRequest.from(
            eventName = "testBridge",
            data = """{"callbackId":"callback_1","params":"{\"value\":7}"}""",
        )

        assertEquals("testBridge", request.methodName)
        assertEquals("""{"value":7}""", request.paramData)
        assertEquals("callback_1", request.callbackId)
        assertFalse(request.oldVersion)
    }

    @Test
    fun `parses old bridge payloads`() {
        val request = BridgeInvocationRequest.from(
            eventName = "native:legacyBridge?42",
            data = "legacyCallback",
        )

        assertEquals("legacyBridge", request.methodName)
        assertEquals("42", request.paramData)
        assertEquals("legacyCallback", request.callbackId)
        assertTrue(request.oldVersion)
    }
}
