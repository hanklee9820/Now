package com.hankle.now.core.service

import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.os.Build
import android.provider.Settings

internal class AndroidPlatformSettingService(
    context: Context,
) : IPlatformSettingService {
    private val appContext = context.applicationContext

    override fun gotoPermissionSettings(): Boolean {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = android.net.Uri.fromParts("package", appContext.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return runCatching {
            appContext.startActivity(intent)
            true
        }.getOrDefault(false)
    }

    override val isLocationEnabled: Boolean
        get() {
            val manager = appContext.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                manager.isLocationEnabled
            } else {
                manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                    manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
            }
        }
}

