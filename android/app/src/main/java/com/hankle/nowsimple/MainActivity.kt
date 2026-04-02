package com.hankle.nowsimple

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.hankle.now.core.NowCore
import com.hankle.now.hybrid.NowHybrid
import com.hankle.now.hybrid.compose.WilmarHybridView
import com.hankle.now.hybrid.jsbridge.JsBridgePlugin
import com.hankle.now.hybrid.jsbridge.NowJsBridge
import com.hankle.now.hybrid.jsbridge.NowJsBridgeManager
import com.hankle.now.hybrid.jsbridge.attribute.JsInterface
import com.hankle.now.hybrid.jsbridge.attribute.JsNativeClass
import com.hankle.now.hybrid.jsbridge.attribute.JsParam
import com.hankle.now.hybrid.web.WilmarHybridWebView
import com.hankle.nowsimple.ui.theme.NowSimpleTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        NowCore.initialize(this)
        NowHybrid.initialize(this)
        enableEdgeToEdge()
        setContent {
            NowSimpleTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    HybridDemoScreen(
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }
}

@Composable
fun HybridDemoScreen(modifier: Modifier = Modifier) {
    var statusText by remember { mutableStateOf("Bridge idle") }
    var hybridView by remember { mutableStateOf<WilmarHybridWebView?>(null) }
    val demoBridge = remember {
        DemoBridge { message ->
            statusText = message
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(text = "Now Hybrid Demo")
        Text(text = statusText)

        Button(
            onClick = {
                hybridView?.loadHtml(DEMO_HTML, baseUrl = "https://demo.now.local/")
                statusText = "Loaded inline demo page"
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Load Demo Page")
        }

        Button(
            onClick = {
                hybridView?.loadUrl("https://example.com")
                statusText = "Loaded https://example.com"
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Load Example.com")
        }

        WilmarHybridView(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            onCreated = { view ->
                hybridView = view
                NowJsBridgeManager.bind(
                    view,
                    JsBridgePlugin.bind(NowJsBridge()),
                    JsBridgePlugin.bind(demoBridge),
                )
                view.loadHtml(DEMO_HTML, baseUrl = "https://demo.now.local/")
            },
        )
    }

    LaunchedEffect(hybridView) {
        if (hybridView != null) {
            statusText = "Hybrid view ready"
        }
    }
}

@JsNativeClass
class DemoBridge(
    private val onMessage: (String) -> Unit,
) {
    @JsInterface("echoMessage")
    fun echoMessage(@JsParam message: String): String {
        val reply = "Native received: $message"
        onMessage(reply)
        return reply
    }
}

private val DEMO_HTML = """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <style>
          body { font-family: sans-serif; padding: 20px; }
          button { display: block; margin: 12px 0; padding: 12px; width: 100%; }
          #result { margin-top: 16px; white-space: pre-wrap; color: #0b5; }
        </style>
      </head>
      <body>
        <h2>Now Hybrid Inline Demo</h2>
        <button onclick="callEcho()">Call echo bridge</button>
        <button onclick="saveStorage()">Save storage</button>
        <button onclick="readStorage()">Read storage</button>
        <div id="result">Waiting for bridge call...</div>
        <script>
          function render(payload) {
            document.getElementById('result').textContent = JSON.stringify(payload, null, 2);
          }

          window.onEcho = function(response) { render(response); };
          window.onStorage = function(response) { render(response); };

          function callEcho() {
            jsBridge.invokeNativeMethod(
              "echoMessage",
              JSON.stringify({ callbackId: "window.onEcho", params: "Hello from H5" })
            );
          }

          function saveStorage() {
            jsBridge.invokeNativeMethod(
              "saveStorage",
              JSON.stringify({
                callbackId: "window.onStorage",
                params: JSON.stringify({ key: "demo_key", value: "saved from web", encrypted: false })
              })
            );
          }

          function readStorage() {
            jsBridge.invokeNativeMethod(
              "getStorage",
              JSON.stringify({
                callbackId: "window.onStorage",
                params: JSON.stringify({ key: "demo_key", encrypted: false })
              })
            );
          }
        </script>
      </body>
    </html>
""".trimIndent()
