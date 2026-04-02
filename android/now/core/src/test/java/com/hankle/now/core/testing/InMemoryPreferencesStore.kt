package com.hankle.now.core.testing

import com.hankle.now.core.storage.PreferencesStore

class InMemoryPreferencesStore : PreferencesStore {
    private val values = linkedMapOf<String, String>()

    override fun contains(key: String): Boolean = values.containsKey(key)

    override fun getString(key: String, defaultValue: String?): String? = values[key] ?: defaultValue

    override fun putString(key: String, value: String?) {
        if (value == null) {
            values.remove(key)
        } else {
            values[key] = value
        }
    }

    override fun remove(key: String) {
        values.remove(key)
    }

    override fun clear() {
        values.clear()
    }

    fun snapshot(): Map<String, String> = values.toMap()
}
