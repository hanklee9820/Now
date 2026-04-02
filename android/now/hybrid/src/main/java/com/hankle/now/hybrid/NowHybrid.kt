package com.hankle.now.hybrid

import android.content.Context

object NowHybrid {
    @Volatile
    private var applicationContext: Context? = null

    fun initialize(context: Context, config: NowHybridConfig = NowHybridConfig()) {
        applicationContext = context.applicationContext
        defaultJavaScriptInterfaceName = config.javascriptInterfaceName
    }

    internal var defaultJavaScriptInterfaceName: String = "jsBridge"
        private set

    internal fun requireContext(): Context {
        return checkNotNull(applicationContext) {
            "NowHybrid has not been initialized. Call NowHybrid.initialize(context) first."
        }
    }
}

data class NowHybridConfig(
    val javascriptInterfaceName: String = "jsBridge",
)

