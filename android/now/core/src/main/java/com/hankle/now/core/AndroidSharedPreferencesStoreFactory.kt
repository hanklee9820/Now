package com.hankle.now.core

import android.content.Context
import com.hankle.now.core.storage.PreferencesStore
import com.hankle.now.core.storage.SharedPreferencesStore

internal class AndroidSharedPreferencesStoreFactory(
    private val context: Context,
) : (String?) -> PreferencesStore {
    override fun invoke(sharedName: String?): PreferencesStore {
        return SharedPreferencesStore(context, sharedName)
    }
}

