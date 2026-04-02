package com.hankle.now.core.service

interface IPlatformSettingService {
    fun gotoPermissionSettings(): Boolean
    val isLocationEnabled: Boolean
}

