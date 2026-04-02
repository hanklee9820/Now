package com.hankle.now.core.storage

interface PreferencesStore {
    fun contains(key: String): Boolean
    fun getString(key: String, defaultValue: String? = null): String?
    fun putString(key: String, value: String?)
    fun remove(key: String)
    fun clear()
}

