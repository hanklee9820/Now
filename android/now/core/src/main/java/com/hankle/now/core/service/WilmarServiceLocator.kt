package com.hankle.now.core.service

import kotlin.reflect.KClass

class WilmarServiceLocator private constructor(
    private val services: MutableMap<KClass<*>, Any>,
) {
    companion object {
        @Volatile
        private var backingInstance: WilmarServiceLocator? = null

        val instance: WilmarServiceLocator
            get() = checkNotNull(backingInstance) {
                "WilmarServiceLocator has not been initialized. Call NowCore.initialize(context) first."
            }

        fun init(services: Map<KClass<*>, Any>) {
            backingInstance = WilmarServiceLocator(services.toMutableMap())
        }

        internal fun resetForTesting() {
            backingInstance = null
        }
    }

    inline fun <reified T : Any> getService(): T {
        return getService(T::class)
    }

    fun <T : Any> getService(type: KClass<T>): T {
        val service = services[type]
            ?: throw IllegalStateException("Service of type ${type.qualifiedName} is not registered.")
        @Suppress("UNCHECKED_CAST")
        return service as T
    }

    fun <T : Any> register(type: KClass<T>, service: T) {
        services[type] = service
    }
}

