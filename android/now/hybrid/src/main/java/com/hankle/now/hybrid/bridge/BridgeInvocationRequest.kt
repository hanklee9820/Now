package com.hankle.now.hybrid.bridge

import com.google.gson.JsonParser

data class BridgeInvocationRequest(
    val methodName: String,
    val paramData: String?,
    val callbackId: String?,
    val oldVersion: Boolean,
) {
    companion object {
        fun from(eventName: String, data: String?): BridgeInvocationRequest {
            if (!eventName.contains("?")) {
                runCatching {
                    val payload = JsonParser.parseString(data.orEmpty()).asJsonObject
                    if (payload.has("callbackId") || payload.has("params")) {
                        return BridgeInvocationRequest(
                            methodName = eventName,
                            paramData = payload.get("params")?.takeIf { !it.isJsonNull }?.asString,
                            callbackId = payload.get("callbackId")?.takeIf { !it.isJsonNull }?.asString,
                            oldVersion = false,
                        )
                    }
                }
            }

            val (methodName, paramData) = parseLegacy(eventName)
            return BridgeInvocationRequest(
                methodName = methodName,
                paramData = paramData,
                callbackId = data,
                oldVersion = true,
            )
        }

        private fun parseLegacy(url: String): Pair<String, String?> {
            if (!url.startsWith("native:")) {
                return url to null
            }

            val body = url.removePrefix("native:")
            val separator = body.indexOf("?")
            if (separator < 0) {
                return body to null
            }

            val methodName = body.substring(0, separator)
            val paramData = body.substring(separator + 1)
            return methodName to paramData
        }
    }
}
