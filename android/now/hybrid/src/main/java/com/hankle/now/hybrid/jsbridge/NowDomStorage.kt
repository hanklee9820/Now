package com.hankle.now.hybrid.jsbridge

import com.hankle.now.core.storage.EncryptedPreferences
import com.hankle.now.core.storage.NowPreferences
import com.hankle.now.hybrid.bridge.BridgeJson

object NowDomStorage {
    const val sharedName: String = "NowDomStorage"

    fun save(key: String, value: Any?, encrypted: Boolean = false) {
        require(key.isNotBlank()) { "key cannot be blank." }
        val payload = BridgeJson.toStoredValue(value)
        if (encrypted) {
            EncryptedPreferences.set(key, payload, sharedName)
        } else {
            NowPreferences.set(key, payload, sharedName)
        }
    }

    fun get(key: String, defaultValue: String = "", encrypted: Boolean = false): String {
        return if (encrypted) {
            EncryptedPreferences.get(key, defaultValue, sharedName)
        } else {
            NowPreferences.get(key, defaultValue, sharedName)
        }
    }

    fun getAny(key: String, encrypted: Boolean = false): Any? {
        return BridgeJson.convertStoredValue(get(key, encrypted = encrypted))
    }

    fun remove(key: String, encrypted: Boolean = false) {
        if (encrypted) {
            EncryptedPreferences.remove(key, sharedName)
        } else {
            NowPreferences.remove(key, sharedName)
        }
    }

    fun clearAll() {
        NowPreferences.clear(sharedName)
        EncryptedPreferences.clear(sharedName)
    }
}

