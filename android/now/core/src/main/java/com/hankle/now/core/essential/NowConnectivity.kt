package com.hankle.now.core.essential

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import com.hankle.now.core.NowCore

object NowConnectivity {
    val networkAccess: NowNetworkAccess
        get() = networkAccess(NowCore.requireContext())

    fun networkAccess(context: Context): NowNetworkAccess {
        val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return NowNetworkAccess.Unknown
        val capabilities = manager.getNetworkCapabilities(manager.activeNetwork) ?: return NowNetworkAccess.None
        val hasInternet = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        val validated = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        return when {
            !hasInternet -> NowNetworkAccess.None
            validated -> NowNetworkAccess.Internet
            else -> NowNetworkAccess.ConstrainedInternet
        }
    }
}

enum class NowNetworkAccess {
    Unknown,
    None,
    Local,
    ConstrainedInternet,
    Internet,
}

