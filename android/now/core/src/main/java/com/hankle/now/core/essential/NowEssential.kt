package com.hankle.now.core.essential

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.hankle.now.core.NowCore

object NowEssential {
    fun openDialer(tel: String, context: Context = NowCore.requireContext()) {
        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$tel")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { context.startActivity(intent) }.getOrElse {
            if (it !is ActivityNotFoundException) {
                throw it
            }
        }
    }

    fun isPhoneDialerSupported(context: Context = NowCore.requireContext()): Boolean {
        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:10086"))
        return intent.resolveActivity(context.packageManager) != null
    }
}

