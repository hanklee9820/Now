package com.hankle.now.core.storage

import android.content.Context

internal class SharedPreferencesStore(
    context: Context,
    sharedName: String?,
) : PreferencesStore {
    private val preferences = context.getSharedPreferences(sharedName ?: DEFAULT_NAME, Context.MODE_PRIVATE)

    override fun contains(key: String): Boolean = preferences.contains(key)

    override fun getString(key: String, defaultValue: String?): String? {
        return preferences.getString(key, defaultValue)
    }

    override fun putString(key: String, value: String?) {
        preferences.edit().putString(key, value).apply()
    }

    override fun remove(key: String) {
        preferences.edit().remove(key).apply()
    }

    override fun clear() {
        preferences.edit().clear().apply()
    }

    private companion object {
        const val DEFAULT_NAME = "NowPreferences"
    }
}

