package com.hankle.now.hybrid.bridge

import com.hankle.now.hybrid.jsbridge.attribute.JsCallback
import com.hankle.now.hybrid.jsbridge.attribute.JsInterface
import com.hankle.now.hybrid.jsbridge.attribute.JsNativeClass
import com.hankle.now.hybrid.jsbridge.attribute.JsParam
import com.hankle.now.hybrid.jsbridge.attribute.WebView
import com.hankle.now.hybrid.jsbridge.dto.HybResponse
import com.hankle.now.hybrid.web.WilmarHybridWebView
import java.lang.reflect.Method

internal class BridgeMethodInvoker(
    hooks: List<Any>,
    private val webViewProvider: () -> WilmarHybridWebView? = { null },
    private val evaluateScript: (String) -> Unit,
) {
    private val hookEntries: List<HookEntry> = hooks.map { hook ->
        require(hook.javaClass.isAnnotationPresent(JsNativeClass::class.java)) {
            "Please add the attribute [JsNativeClass] on your class before binding it to JsBridgePlugin."
        }
        HookEntry(hook, collectMethods(hook))
    }

    fun dispatch(request: BridgeInvocationRequest): Boolean {
        val matches = hookEntries
            .flatMap { entry ->
                entry.methods
                    .filter { method -> resolveMethodName(method) == request.methodName }
                    .map { method -> entry.hook to method }
            }

        if (matches.isEmpty()) {
            return false
        }

        if (matches.size > 1) {
            callback(request.callbackId, HybResponse.error("${request.methodName} has multiple matching native methods.", request.oldVersion))
            return true
        }

        val (hook, method) = matches.single()
        return runCatching {
            val args = buildArguments(method, request)
            val result = method.invoke(hook, *args)
            handleReturnValue(request, result, method)
            true
        }.getOrElse { error ->
            callback(request.callbackId, HybResponse.exception(error, request.oldVersion))
            true
        }
    }

    private fun buildArguments(method: Method, request: BridgeInvocationRequest): Array<Any?> {
        val parameters = method.parameters
        return Array(parameters.size) { index ->
            val parameter = parameters[index]
            when {
                parameter.isAnnotationPresent(JsParam::class.java) -> {
                    BridgeJson.convertParam(request.paramData, parameter.type)
                }
                parameter.isAnnotationPresent(JsCallback::class.java) -> {
                    createCallback(parameter.type, request)
                }
                parameter.isAnnotationPresent(WebView::class.java) -> {
                    webViewProvider()
                }
                else -> null
            }
        }
    }

    private fun createCallback(parameterType: Class<*>, request: BridgeInvocationRequest): Any {
        return when (parameterType.name) {
            "kotlin.jvm.functions.Function0" -> object : Function0<Unit> {
                override fun invoke() {
                    callback(request.callbackId, HybResponse.succeed(request.oldVersion))
                }
            }
            "kotlin.jvm.functions.Function1" -> object : Function1<Any?, Unit> {
                override fun invoke(value: Any?) {
                    callback(request.callbackId, HybResponse.succeed(value, request.oldVersion))
                }
            }
            else -> throw IllegalArgumentException("Unsupported callback parameter type: ${parameterType.name}")
        }
    }

    private fun handleReturnValue(request: BridgeInvocationRequest, result: Any?, method: Method) {
        val hasCallbackParam = method.parameters.any { it.isAnnotationPresent(JsCallback::class.java) }
        if (hasCallbackParam) {
            return
        }

        when (result) {
            null -> callback(request.callbackId, HybResponse.succeed(request.oldVersion))
            is HybResponse -> callback(request.callbackId, result)
            else -> callback(request.callbackId, HybResponse.succeed(result, request.oldVersion))
        }
    }

    private fun callback(callbackId: String?, response: HybResponse) {
        if (callbackId.isNullOrBlank()) {
            return
        }
        evaluateScript(BridgeJson.toCallbackScript(callbackId, response))
    }

    private fun collectMethods(hook: Any): List<Method> {
        return hook.javaClass.methods.filter { it.isAnnotationPresent(JsInterface::class.java) }
    }

    private fun resolveMethodName(method: Method): String {
        val annotation = method.getAnnotation(JsInterface::class.java)
        return annotation?.name?.takeIf { it.isNotBlank() } ?: method.name
    }

    private data class HookEntry(
        val hook: Any,
        val methods: List<Method>,
    )
}
