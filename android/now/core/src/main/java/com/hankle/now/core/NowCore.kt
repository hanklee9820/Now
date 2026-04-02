package com.hankle.now.core

import android.content.Context
import com.hankle.now.core.file.AndroidFileSystemService
import com.hankle.now.core.file.IFileSystemService
import com.hankle.now.core.service.AndroidPlatformSettingService
import com.hankle.now.core.service.IPlatformSettingService
import com.hankle.now.core.service.WilmarServiceLocator
import com.hankle.now.core.storage.NowPreferences
import kotlin.reflect.KClass

object NowCore {
    @Volatile
    private var applicationContext: Context? = null

    fun initialize(context: Context, config: NowCoreConfig = NowCoreConfig()) {
        val appContext = context.applicationContext
        applicationContext = appContext

        val services = linkedMapOf<KClass<*>, Any>()
        val platformSettingService = config.platformSettingService ?: AndroidPlatformSettingService(appContext)
        val fileSystemService = config.fileSystemService ?: AndroidFileSystemService(appContext)
        services[IPlatformSettingService::class] = platformSettingService
        services[IFileSystemService::class] = fileSystemService

        WilmarServiceLocator.init(services)
        NowPreferences.installStoreFactory(AndroidSharedPreferencesStoreFactory(appContext))
    }

    internal fun requireContext(): Context {
        return checkNotNull(applicationContext) {
            "NowCore has not been initialized. Call NowCore.initialize(context) first."
        }
    }

    internal fun resetForTesting() {
        applicationContext = null
        WilmarServiceLocator.resetForTesting()
        NowPreferences.resetForTesting()
    }
}

data class NowCoreConfig(
    val platformSettingService: IPlatformSettingService? = null,
    val fileSystemService: IFileSystemService? = null,
)

