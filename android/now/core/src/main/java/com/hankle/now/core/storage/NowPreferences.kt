package com.hankle.now.core.storage

import java.time.Instant
import java.time.format.DateTimeParseException

object NowPreferences {
    private var storeFactory: ((String?) -> PreferencesStore)? = null
    private val storeCache = mutableMapOf<String?, PreferencesStore>()

    fun containsKey(key: String, sharedName: String? = null): Boolean {
        return resolveStore(sharedName).contains(key)
    }

    fun remove(key: String, sharedName: String? = null) {
        resolveStore(sharedName).remove(key)
    }

    fun clear(sharedName: String? = null) {
        resolveStore(sharedName).clear()
    }

    fun set(key: String, value: Long, sharedName: String? = null) = setRaw(key, value.toString(), sharedName)
    fun get(key: String, defaultValue: Long, sharedName: String? = null): Long =
        getRaw(key, sharedName)?.toLongOrNull() ?: defaultValue

    fun set(key: String, value: String, sharedName: String? = null) = setRaw(key, value, sharedName)
    fun get(key: String, defaultValue: String? = null, sharedName: String? = null): String =
        getRaw(key, sharedName) ?: defaultValue.orEmpty()

    fun set(key: String, value: Boolean, sharedName: String? = null) = setRaw(key, value.toString(), sharedName)
    fun get(key: String, defaultValue: Boolean = false, sharedName: String? = null): Boolean =
        getRaw(key, sharedName)?.toBooleanStrictOrNull() ?: defaultValue

    fun set(key: String, value: Int, sharedName: String? = null) = setRaw(key, value.toString(), sharedName)
    fun get(key: String, defaultValue: Int = 0, sharedName: String? = null): Int =
        getRaw(key, sharedName)?.toIntOrNull() ?: defaultValue

    fun set(key: String, value: Double, sharedName: String? = null) = setRaw(key, value.toString(), sharedName)
    fun get(key: String, defaultValue: Double = .0, sharedName: String? = null): Double =
        getRaw(key, sharedName)?.toDoubleOrNull() ?: defaultValue

    fun set(key: String, value: Float, sharedName: String? = null) = setRaw(key, value.toString(), sharedName)
    fun get(key: String, defaultValue: Float = 0f, sharedName: String? = null): Float =
        getRaw(key, sharedName)?.toFloatOrNull() ?: defaultValue

    fun set(key: String, value: Instant, sharedName: String? = null) = setRaw(key, value.toString(), sharedName)
    fun get(key: String, defaultValue: Instant = Instant.EPOCH, sharedName: String? = null): Instant {
        val rawValue = getRaw(key, sharedName) ?: return defaultValue
        return try {
            Instant.parse(rawValue)
        } catch (_: DateTimeParseException) {
            defaultValue
        }
    }

    internal fun installStoreFactory(factory: (String?) -> PreferencesStore) {
        storeFactory = factory
        storeCache.clear()
    }

    internal fun installStoreFactoryForTesting(factory: (String?) -> PreferencesStore) {
        installStoreFactory(factory)
    }

    internal fun resetForTesting() {
        storeFactory = null
        storeCache.clear()
    }

    private fun setRaw(key: String, value: String?, sharedName: String?) {
        resolveStore(sharedName).putString(key, value)
    }

    private fun getRaw(key: String, sharedName: String?): String? {
        return resolveStore(sharedName).getString(key, null)
    }

    private fun resolveStore(sharedName: String?): PreferencesStore {
        return storeCache.getOrPut(sharedName) {
            checkNotNull(storeFactory) {
                "NowPreferences has not been initialized. Call NowCore.initialize(context) first."
            }.invoke(sharedName)
        }
    }
}

