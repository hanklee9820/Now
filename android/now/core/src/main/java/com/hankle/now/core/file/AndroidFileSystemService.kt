package com.hankle.now.core.file

import android.content.Context

internal class AndroidFileSystemService(
    context: Context,
) : IFileSystemService {
    private val appContext = context.applicationContext

    override val cachePath: String
        get() = appContext.cacheDir.absolutePath

    override val appDataPath: String
        get() = appContext.filesDir.absolutePath
}

