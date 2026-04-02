import Combine
import Foundation
import NowCore
import NowHybrid
import SwiftUI

@MainActor
final class HybridDemoViewModel: ObservableObject {
    enum Source: String, CaseIterable, Identifiable {
        case online
        case bundle
        case sandbox

        var id: String { rawValue }

        var title: String {
            switch self {
            case .online:
                return "Online"
            case .bundle:
                return "Bundle"
            case .sandbox:
                return "Sandbox"
            }
        }
    }

    @Published var selectedSource: Source = .online
    @Published var progress: Int = 0
    @Published var statusMessage: String = "Ready"

    let webView: WilmarHybridWebView

    init() {
        webView = WilmarHybridWebView()
        configureCallbacks()
        registerBridges()
        prepareSandboxDemo()
        load(.online)
    }

    deinit {
        webView.dispose()
    }

    func load(_ source: Source) {
        selectedSource = source
        switch source {
        case .online:
            statusMessage = "Loading online page: https://example.com"
            webView.load(url: URL(string: "https://example.com")!)
        case .bundle:
            statusMessage = "Loading bundle demo: localx://bundle/Demo/hybrid-demo.html"
            webView.load(source: .bundle("Demo/hybrid-demo.html"))
        case .sandbox:
            statusMessage = "Loading sandbox demo: localx://sandbox/demo/sandbox-demo.html"
            webView.load(source: .sandbox("demo/sandbox-demo.html"))
        }
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            statusMessage = "No page to go back to yet."
        }
    }

    private func configureCallbacks() {
        webView.onProgressChanged = { [weak self] value in
            Task { @MainActor in
                self?.progress = value
            }
        }
        webView.onJavaScriptEvaluation = { [weak self] script in
            Task { @MainActor in
                let preview = script.replacingOccurrences(of: "\n", with: " ")
                self?.statusMessage = "Native callback sent: \(preview.prefix(80))"
            }
        }
    }

    private func registerBridges() {
        do {
            try webView.bridgeManager.register(NowJsBridge(), to: webView)
            try webView.bridgeManager.register(DemoBridge(), to: webView)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func prepareSandboxDemo() {
        let baseURL = URL(fileURLWithPath: NowFileSystem.appDataPath, isDirectory: true)
        let demoDirectory = baseURL.appendingPathComponent("demo", isDirectory: true)
        try? FileManager.default.createDirectory(at: demoDirectory, withIntermediateDirectories: true)
        let htmlURL = demoDirectory.appendingPathComponent("sandbox-demo.html")
        let html = DemoHTML.page(title: "Sandbox Demo", accent: "#0E7490", sourceLabel: "sandbox")
        try? html.write(to: htmlURL, atomically: true, encoding: .utf8)
    }
}

private struct DemoBridge: INowBridge {
    let supportedMethods: Set<String> = ["echo", "delayedEcho", "deviceInfo"]

    func handle(request: BridgeInvocationRequest, webView: WilmarHybridWebView?) async throws -> AnySendable? {
        switch request.methodName {
        case "echo":
            return AnySendable("echo:\(request.paramData ?? "")")
        case "delayedEcho":
            try await Task.sleep(for: .milliseconds(250))
            return AnySendable("async:\(request.paramData ?? "")")
        case "deviceInfo":
            return AnySendable([
                "platform": "iOS",
                "network": String(describing: NowConnectivity.networkAccess),
                "appDataPath": NowFileSystem.appDataPath,
            ])
        default:
            return AnySendable(nil)
        }
    }
}

private enum DemoHTML {
    static func page(title: String, accent: String, sourceLabel: String) -> String {
        """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width,initial-scale=1" />
          <title>\(title)</title>
          <style>
            :root {
              color-scheme: light;
              --bg: #f6f7f4;
              --card: rgba(255, 255, 255, 0.84);
              --text: #172033;
              --muted: #5b6579;
              --accent: \(accent);
              --accent-soft: color-mix(in srgb, \(accent) 14%, white);
              --border: rgba(23, 32, 51, 0.12);
            }
            * { box-sizing: border-box; }
            body {
              margin: 0;
              padding: 28px;
              font-family: "Avenir Next", "Segoe UI", sans-serif;
              background:
                radial-gradient(circle at top right, rgba(255,255,255,0.9), transparent 28%),
                linear-gradient(135deg, #eef4ff 0%, var(--bg) 52%, #fff7ed 100%);
              color: var(--text);
            }
            .shell {
              max-width: 900px;
              margin: 0 auto;
              display: grid;
              gap: 18px;
            }
            .hero, .panel {
              background: var(--card);
              border: 1px solid var(--border);
              border-radius: 24px;
              box-shadow: 0 22px 50px rgba(23, 32, 51, 0.08);
              backdrop-filter: blur(10px);
            }
            .hero {
              padding: 28px;
              display: grid;
              gap: 12px;
            }
            .eyebrow {
              width: fit-content;
              padding: 6px 12px;
              border-radius: 999px;
              background: var(--accent-soft);
              color: var(--accent);
              font-size: 12px;
              font-weight: 700;
              letter-spacing: 0.08em;
              text-transform: uppercase;
            }
            h1 {
              margin: 0;
              font-size: clamp(30px, 5vw, 50px);
              line-height: 1.02;
            }
            p {
              margin: 0;
              color: var(--muted);
              line-height: 1.6;
            }
            .grid {
              display: grid;
              grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
              gap: 14px;
            }
            button {
              border: 0;
              border-radius: 18px;
              padding: 14px 16px;
              text-align: left;
              font: inherit;
              background: #fff;
              color: var(--text);
              box-shadow: inset 0 0 0 1px var(--border);
            }
            button strong {
              display: block;
              margin-bottom: 4px;
            }
            button span {
              color: var(--muted);
              font-size: 13px;
            }
            .panel {
              padding: 18px 20px;
            }
            pre {
              margin: 0;
              padding: 16px;
              min-height: 220px;
              white-space: pre-wrap;
              overflow-wrap: anywhere;
              border-radius: 18px;
              background: #101827;
              color: #d9e7ff;
              font: 13px/1.5 "SFMono-Regular", ui-monospace, monospace;
            }
          </style>
        </head>
        <body>
          <div class="shell">
            <section class="hero">
              <div class="eyebrow">NowHybrid \(sourceLabel)</div>
              <h1>\(title)</h1>
              <p>This page runs inside <code>WKWebView</code> through <code>localx://</code>. Use the buttons below to verify native bridge calls, async callbacks, and shared storage.</p>
            </section>
            <section class="grid">
              <button onclick="callBridge('echo', 'hello-\(sourceLabel)')">
                <strong>Sync Echo</strong>
                <span>Calls the custom demo bridge and returns immediately.</span>
              </button>
              <button onclick="callBridge('delayedEcho', 'delayed-\(sourceLabel)')">
                <strong>Async Echo</strong>
                <span>Waits briefly on native side before sending the callback.</span>
              </button>
              <button onclick="saveStorage()">
                <strong>Save Storage</strong>
                <span>Persists a value through <code>NowJsBridge</code>.</span>
              </button>
              <button onclick="getStorage()">
                <strong>Read Storage</strong>
                <span>Reads the same key back from native storage.</span>
              </button>
              <button onclick="callBridge('deviceInfo', '')">
                <strong>Device Info</strong>
                <span>Returns simple runtime information from the app.</span>
              </button>
            </section>
            <section class="panel">
              <pre id="log">Waiting for bridge actions...</pre>
            </section>
          </div>
          <script>
            const logElement = document.getElementById('log');
            function logLine(label, payload) {
              const text = typeof payload === 'string' ? payload : JSON.stringify(payload, null, 2);
              logElement.textContent = `[${new Date().toLocaleTimeString()}] ${label}\\n${text}\\n\\n` + logElement.textContent;
            }
            window.demoCallbacks = {
              handle(response) {
                logLine('callback', response);
              }
            };
            function callBridge(methodName, params) {
              window.jsBridge.invokeNativeMethod({
                methodName,
                params,
                callbackId: 'window.demoCallbacks.handle'
              });
            }
            function saveStorage() {
              window.jsBridge.invokeNativeMethod({
                methodName: 'saveStorage',
                params: JSON.stringify({
                  key: 'demo_key_\(sourceLabel)',
                  value: 'saved-from-\(sourceLabel)',
                  encrypted: false
                }),
                callbackId: 'window.demoCallbacks.handle'
              });
            }
            function getStorage() {
              window.jsBridge.invokeNativeMethod({
                methodName: 'getStorage',
                params: JSON.stringify({
                  key: 'demo_key_\(sourceLabel)',
                  encrypted: false
                }),
                callbackId: 'window.demoCallbacks.handle'
              });
            }
            logLine('ready', 'Bridge name: jsBridge');
          </script>
        </body>
        </html>
        """
    }
}
