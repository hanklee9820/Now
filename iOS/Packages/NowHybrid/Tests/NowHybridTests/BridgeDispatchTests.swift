import Foundation
import NowCore
import Testing
@testable import NowHybrid

struct BridgeDispatchTests {
    @Test
    func dispatchesSyncBridgeAndEvaluatesCallbackScript() async throws {
        let webView = WilmarHybridWebView()
        let manager = NowJsBridgeManager()
        let bridge = EchoBridge()
        let recorder = EvaluationRecorder()
        webView.onJavaScriptEvaluation = { recorder.record($0) }

        try manager.register(bridge, to: webView)
        await manager.dispatch(
            eventName: "echoMessage",
            payload: #"{"callbackId":"window.cb","params":"hello"}"#,
            on: webView
        )

        #expect(recorder.values.contains { $0.contains(#""data":"native:hello""#) })
    }

    @Test
    func dispatchesAsyncBridgeAndEvaluatesCallbackScript() async throws {
        let webView = WilmarHybridWebView()
        let manager = NowJsBridgeManager()
        let bridge = AsyncBridge()
        let recorder = EvaluationRecorder()
        webView.onJavaScriptEvaluation = { recorder.record($0) }

        try manager.register(bridge, to: webView)
        await manager.dispatch(
            eventName: "asyncMessage",
            payload: #"{"callbackId":"window.asyncCb","params":"42"}"#,
            on: webView
        )

        #expect(recorder.values.contains { $0.contains(#""data":"async:42""#) })
    }

    @Test
    func nowJsBridgePersistsStorageValues() async throws {
        NowCore.initialize(context: .live)
        let webView = WilmarHybridWebView()
        let manager = NowJsBridgeManager()
        let recorder = EvaluationRecorder()
        webView.onJavaScriptEvaluation = { recorder.record($0) }

        try manager.register(NowJsBridge(), to: webView)
        await manager.dispatch(
            eventName: "saveStorage",
            payload: #"{"callbackId":"window.storageSave","params":"{\"key\":\"demo_key\",\"value\":\"demo_value\",\"encrypted\":false}"}"#,
            on: webView
        )
        await manager.dispatch(
            eventName: "getStorage",
            payload: #"{"callbackId":"window.storageGet","params":"{\"key\":\"demo_key\",\"encrypted\":false}"}"#,
            on: webView
        )

        #expect(recorder.values.contains { $0.contains(#""data":"demo_value""#) })
    }
}

private struct EchoBridge: INowBridge {
    let supportedMethods: Set<String> = ["echoMessage"]

    func handle(request: BridgeInvocationRequest, webView: WilmarHybridWebView?) async throws -> AnySendable? {
        AnySendable("native:\(request.paramData ?? "")")
    }
}

private struct AsyncBridge: INowBridge {
    let supportedMethods: Set<String> = ["asyncMessage"]

    func handle(request: BridgeInvocationRequest, webView: WilmarHybridWebView?) async throws -> AnySendable? {
        try await Task.sleep(for: .milliseconds(10))
        return AnySendable("async:\(request.paramData ?? "")")
    }
}

private final class EvaluationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var values: [String] = []

    func record(_ value: String) {
        lock.lock()
        values.append(value)
        lock.unlock()
    }
}
