package com.hankle.now.hybrid.web

import android.app.Activity
import android.view.View
import android.view.ViewGroup
import android.webkit.GeolocationPermissions
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.core.view.children

internal class WilmarWebChromeClient(
    private val owner: WilmarHybridWebView,
) : WebChromeClient() {
    private var customView: View? = null
    private var customViewCallback: CustomViewCallback? = null

    override fun onProgressChanged(view: WebView?, newProgress: Int) {
        owner.notifyProgress(newProgress)
    }

    override fun onShowCustomView(view: View?, callback: CustomViewCallback?) {
        val activity = owner.context as? Activity ?: return super.onShowCustomView(view, callback)
        val container = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
        if (view == null || customView != null) {
            callback?.onCustomViewHidden()
            return
        }

        customView = view
        customViewCallback = callback
        container.addView(
            view,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        owner.visibility = View.GONE
        owner.notifyFullScreenChanged(true)
    }

    override fun onHideCustomView() {
        val activity = owner.context as? Activity ?: return super.onHideCustomView()
        val container = activity.findViewById<ViewGroup>(android.R.id.content) ?: return
        val view = customView ?: return
        container.children.firstOrNull { it === view }?.let(container::removeView)
        customView = null
        customViewCallback?.onCustomViewHidden()
        customViewCallback = null
        owner.visibility = View.VISIBLE
        owner.notifyFullScreenChanged(false)
    }

    override fun onGeolocationPermissionsShowPrompt(
        origin: String?,
        callback: GeolocationPermissions.Callback?,
    ) {
        callback?.invoke(origin, true, true)
    }
}

