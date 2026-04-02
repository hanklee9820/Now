package com.hankle.now.hybrid.compose

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.hankle.now.hybrid.web.WilmarHybridWebView

@Composable
fun WilmarHybridView(
    modifier: Modifier = Modifier,
    onCreated: (WilmarHybridWebView) -> Unit = {},
    update: (WilmarHybridWebView) -> Unit = {},
) {
    AndroidView(
        modifier = modifier,
        factory = { context ->
            WilmarHybridWebView(context).also(onCreated)
        },
        update = update,
    )
}

