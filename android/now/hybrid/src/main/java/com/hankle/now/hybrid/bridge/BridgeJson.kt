package com.hankle.now.hybrid.bridge

import com.google.gson.GsonBuilder
import com.google.gson.JsonArray
import com.google.gson.JsonElement
import com.google.gson.JsonNull
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import com.google.gson.JsonPrimitive
import com.hankle.now.hybrid.jsbridge.dto.HybResponse
import java.lang.reflect.Type

internal object BridgeJson {
    private val gson = GsonBuilder()
        .disableHtmlEscaping()
        .create()

    fun toCallbackScript(callbackId: String, response: HybResponse): String {
        return "$callbackId(${toJson(response)})"
    }

    fun toJson(value: Any?): String = gson.toJson(value)

    fun <T : Any> convertParam(rawValue: String?, targetType: Class<T>): T? {
        if (rawValue == null) return null

        @Suppress("UNCHECKED_CAST")
        return when (targetType) {
            String::class.java -> rawValue as T
            java.lang.Integer.TYPE, Int::class.javaObjectType -> rawValue.toIntOrNull() as T?
            java.lang.Long.TYPE, Long::class.javaObjectType -> rawValue.toLongOrNull() as T?
            java.lang.Double.TYPE, Double::class.javaObjectType -> rawValue.toDoubleOrNull() as T?
            java.lang.Float.TYPE, Float::class.javaObjectType -> rawValue.toFloatOrNull() as T?
            java.lang.Boolean.TYPE, Boolean::class.javaObjectType -> rawValue.toBooleanStrictOrNull() as T?
            else -> gson.fromJson(rawValue, targetType)
        }
    }

    fun convertStoredValue(rawValue: String?): Any? {
        if (rawValue.isNullOrBlank()) {
            return null
        }
        val envelope = JsonParser.parseString(rawValue).asJsonObject
        return fromJsonElement(envelope.get("value"))
    }

    fun toStoredValue(value: Any?): String {
        val envelope = JsonObject()
        envelope.add("value", gson.toJsonTree(value))
        return gson.toJson(envelope)
    }

    private fun fromJsonElement(value: JsonElement?): Any? {
        if (value == null || value is JsonNull) {
            return null
        }

        if (value is JsonPrimitive) {
            return when {
                value.isBoolean -> value.asBoolean
                value.isNumber -> value.asNumber
                else -> value.asString
            }
        }

        if (value is JsonArray) {
            return value.map(::fromJsonElement)
        }

        if (value is JsonObject) {
            return value.entrySet().associate { it.key to fromJsonElement(it.value) }
        }

        return gson.fromJson(value, Any::class.java)
    }
}
