import Foundation
import NowCore
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if canImport(WebKit)
import WebKit
#endif
#if canImport(UIKit)
import UIKit
import SwiftUI
#endif

public struct NowHybridConfig: Sendable {
    public var bridgeName: String
    public var isInspectable: Bool

    public init(bridgeName: String = "jsBridge", isInspectable: Bool = false) {
        self.bridgeName = bridgeName
        self.isInspectable = isInspectable
    }
}

public enum NowHybrid {
    nonisolated(unsafe) private static var config = NowHybridConfig()

    public static func initialize(config: NowHybridConfig = .init()) {
        self.config = config
    }

    static var currentConfig: NowHybridConfig {
        config
    }
}

public struct WilmarLocalSource: Equatable, Sendable {
    public static let scheme = "localx"

    public let url: URL

    public init?(url: URL) {
        guard url.scheme == Self.scheme,
              let host = url.host,
              Location(rawValue: host) != nil else {
            return nil
        }
        self.url = url
    }

    public static func bundle(_ path: String) -> WilmarLocalSource {
        WilmarLocalSource(url: URL(string: "\(scheme)://bundle/\(sanitized(path))")!)!
    }

    public static func sandbox(_ path: String) -> WilmarLocalSource {
        WilmarLocalSource(url: URL(string: "\(scheme)://sandbox/\(sanitized(path))")!)!
    }

    public var location: Location? {
        guard url.scheme == Self.scheme else {
            return nil
        }
        return url.host.flatMap(Location.init(rawValue:))
    }

    public var path: String {
        url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    public func resolvedFileURL(bundle: Bundle = .main) -> URL? {
        guard let location else {
            return nil
        }

        switch location {
        case .bundle:
            guard let baseURL = bundle.resourceURL else {
                return nil
            }
            return baseURL.appendingPathComponent(path)
        case .sandbox:
            let baseURL = URL(fileURLWithPath: NowFileSystem.appDataPath, isDirectory: true)
            return baseURL.appendingPathComponent(path)
        }
    }

    private static func sanitized(_ path: String) -> String {
        path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    public enum Location: String, Sendable {
        case bundle
        case sandbox
    }
}

public struct BridgeInvocationRequest: Sendable, Equatable {
    public let methodName: String
    public let paramData: String?
    public let callbackId: String?
    public let oldVersion: Bool

    static func from(eventName: String, payload: String?) -> BridgeInvocationRequest {
        if eventName.hasPrefix("native:") {
            let legacyName = String(eventName.dropFirst("native:".count))
            let parts = legacyName.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
            return BridgeInvocationRequest(
                methodName: parts.first.map(String.init) ?? legacyName,
                paramData: parts.count > 1 ? String(parts[1]) : nil,
                callbackId: payload,
                oldVersion: true
            )
        }

        guard let payload,
              let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return BridgeInvocationRequest(methodName: eventName, paramData: payload, callbackId: nil, oldVersion: false)
        }

        return BridgeInvocationRequest(
            methodName: (json["methodName"] as? String) ?? eventName,
            paramData: stringify(json["params"] ?? json["data"]),
            callbackId: json["callbackId"] as? String,
            oldVersion: json["oldVersion"] as? Bool ?? false
        )
    }

    static func from(messageBody body: Any) -> BridgeInvocationRequest? {
        if let body = body as? [String: Any] {
            let eventName = (body["methodName"] as? String) ?? (body["eventName"] as? String) ?? ""
            if eventName.isEmpty {
                return nil
            }
            let payload: [String: Any] = [
                "callbackId": body["callbackId"] as Any,
                "params": body["params"] as Any,
                "oldVersion": body["oldVersion"] as Any,
            ].compactMapValues { value in
                if value is NSNull {
                    return nil
                }
                return value
            }
            let data = try? JSONSerialization.data(withJSONObject: payload, options: [])
            let json = data.flatMap { String(data: $0, encoding: .utf8) }
            return from(eventName: eventName, payload: json)
        }

        if let body = body as? String {
            return from(eventName: body, payload: nil)
        }

        return nil
    }

    private static func stringify(_ value: Any?) -> String? {
        guard let value else {
            return nil
        }
        if value is NSNull {
            return nil
        }
        if let string = value as? String {
            return string
        }
        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value, options: []),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return String(describing: value)
    }
}

public enum HybResponse: Sendable, Equatable {
    case succeed(AnySendable?)
    case error(String)

    func callbackScript(for callbackId: String) -> String {
        let payload: [String: Any]
        switch self {
        case let .succeed(data):
            payload = [
                "success": true,
                "data": data?.jsonObject ?? NSNull(),
                "error": NSNull(),
            ]
        case let .error(message):
            payload = [
                "success": false,
                "data": NSNull(),
                "error": message,
            ]
        }

        let json = Self.serialize(payload) ?? #"{"success":false,"data":null,"error":"serialization_failure"}"#
        let callbackLiteral = Self.serialize(callbackId) ?? #""__missing_callback__""#
        return "window.__nowHybridReceiveResponse(\(callbackLiteral), \(json));"
    }

    private static func serialize(_ value: Any) -> String? {
        if let string = value as? String,
           let data = try? JSONSerialization.data(withJSONObject: [string], options: []),
           var json = String(data: data, encoding: .utf8) {
            json.removeFirst()
            json.removeLast()
            return json
        }

        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
}

public protocol INowBridge: Sendable {
    var supportedMethods: Set<String> { get }
    func handle(request: BridgeInvocationRequest, webView: WilmarHybridWebView?) async throws -> AnySendable?
}

public final class NowJsBridgeManager: @unchecked Sendable {
    private let lock = NSLock()
    private var registrations: [ObjectIdentifier: [String: any INowBridge]] = [:]

    public init() {}

    public func register(_ bridge: any INowBridge, to webView: WilmarHybridWebView) throws {
        let key = ObjectIdentifier(webView)
        lock.lock()
        defer { lock.unlock() }

        var methods = registrations[key, default: [:]]
        for method in bridge.supportedMethods {
            if methods[method] != nil {
                throw NowHybridError.duplicateMethod(method)
            }
            methods[method] = bridge
        }
        registrations[key] = methods
    }

    public func dispatch(eventName: String, payload: String?, on webView: WilmarHybridWebView) async {
        let request = BridgeInvocationRequest.from(eventName: eventName, payload: payload)
        await dispatch(request: request, on: webView)
    }

    func dispatch(messageBody: Any, on webView: WilmarHybridWebView) async {
        guard let request = BridgeInvocationRequest.from(messageBody: messageBody) else {
            return
        }
        await dispatch(request: request, on: webView)
    }

    private func dispatch(request: BridgeInvocationRequest, on webView: WilmarHybridWebView) async {
        let response: HybResponse

        do {
            guard let bridge = bridge(for: request.methodName, on: webView) else {
                throw NowHybridError.unregisteredMethod(request.methodName)
            }
            let result = try await bridge.handle(request: request, webView: webView)
            response = .succeed(result)
        } catch {
            response = .error(error.localizedDescription)
        }

        guard let callbackId = request.callbackId else {
            return
        }
        await webView.evaluateJavaScript(response.callbackScript(for: callbackId))
    }

    private func bridge(for method: String, on webView: WilmarHybridWebView) -> (any INowBridge)? {
        let key = ObjectIdentifier(webView)
        lock.lock()
        defer { lock.unlock() }
        return registrations[key]?[method]
    }
}

public struct AnySendable: @unchecked Sendable, Equatable {
    public let base: Any?

    public init(_ base: Any?) {
        self.base = base
    }

    public static func == (lhs: AnySendable, rhs: AnySendable) -> Bool {
        Self.render(lhs.base) == Self.render(rhs.base)
    }

    var jsonObject: Any {
        Self.convert(base)
    }

    private static func convert(_ value: Any?) -> Any {
        guard let value else {
            return NSNull()
        }
        if value is NSNull {
            return NSNull()
        }
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number
        case let bool as Bool:
            return bool
        case let int as Int:
            return int
        case let int64 as Int64:
            return int64
        case let double as Double:
            return double
        case let float as Float:
            return Double(float)
        case let date as Date:
            return ISO8601DateFormatter().string(from: date)
        case let array as [Any]:
            return array.map(convert)
        case let dictionary as [String: Any]:
            return dictionary.mapValues(convert)
        default:
            return String(describing: value)
        }
    }

    private static func render(_ value: Any?) -> String {
        if JSONSerialization.isValidJSONObject(convert(value)),
           let data = try? JSONSerialization.data(withJSONObject: convert(value), options: [.sortedKeys]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return String(describing: value)
    }
}

public final class NowJsBridge: INowBridge {
    public let supportedMethods: Set<String> = ["saveStorage", "getStorage", "removeStorage"]

    private let defaultSharedName: String?

    public init(sharedName: String? = nil) {
        self.defaultSharedName = sharedName
    }

    public func handle(request: BridgeInvocationRequest, webView: WilmarHybridWebView?) async throws -> AnySendable? {
        let payload = try StoragePayload.decode(from: request.paramData)
        let sharedName = payload.sharedName ?? defaultSharedName

        switch request.methodName {
        case "saveStorage":
            let value = payload.value ?? ""
            if payload.encrypted {
                EncryptedPreferences.set(payload.key, value: value, sharedName: sharedName)
            } else {
                NowPreferences.set(payload.key, value: value, sharedName: sharedName)
            }
            return AnySendable(value)
        case "getStorage":
            let value = payload.encrypted
                ? EncryptedPreferences.get(payload.key, sharedName: sharedName)
                : NowPreferences.get(payload.key, sharedName: sharedName)
            return AnySendable(value)
        case "removeStorage":
            if payload.encrypted {
                EncryptedPreferences.remove(payload.key, sharedName: sharedName)
            } else {
                NowPreferences.remove(payload.key, sharedName: sharedName)
            }
            return AnySendable(true)
        default:
            throw NowHybridError.unregisteredMethod(request.methodName)
        }
    }
}

public enum NowHybridError: LocalizedError, Equatable {
    case duplicateMethod(String)
    case unregisteredMethod(String)
    case invalidPayload(String)

    public var errorDescription: String? {
        switch self {
        case let .duplicateMethod(method):
            return "duplicate bridge method: \(method)"
        case let .unregisteredMethod(method):
            return "unregistered bridge method: \(method)"
        case let .invalidPayload(reason):
            return "invalid bridge payload: \(reason)"
        }
    }
}

private struct StoragePayload: Decodable {
    let key: String
    let value: String?
    let encrypted: Bool
    let sharedName: String?

    static func decode(from raw: String?) throws -> StoragePayload {
        guard let raw,
              let data = raw.data(using: .utf8) else {
            throw NowHybridError.invalidPayload("missing storage payload")
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(StoragePayload.self, from: data)
        } catch {
            throw NowHybridError.invalidPayload(error.localizedDescription)
        }
    }
}

#if canImport(UIKit)
public final class WilmarHybridWebView: UIView {
    public var onProgressChanged: ((Int) -> Void)?
    public var onFullScreenChanged: ((Bool) -> Void)?
    public var onJavaScriptEvaluation: ((String) -> Void)?
    public let bridgeManager: NowJsBridgeManager

    private let nativeWebView: WKWebView
    private let messageHandler: ScriptMessageHandlerProxy
    private let schemeHandler: LocalSchemeHandler
    private var progressObserver: NSKeyValueObservation?

    public override init(frame: CGRect) {
        let bridgeManager = NowJsBridgeManager()
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let messageHandler = ScriptMessageHandlerProxy()
        let schemeHandler = LocalSchemeHandler()

        configuration.userContentController = userContentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: WilmarLocalSource.scheme)

        let nativeWebView = WKWebView(frame: .zero, configuration: configuration)
        self.bridgeManager = bridgeManager
        self.nativeWebView = nativeWebView
        self.messageHandler = messageHandler
        self.schemeHandler = schemeHandler

        super.init(frame: frame)
        setupWebView(userContentController: userContentController)
    }

    public required init?(coder: NSCoder) {
        let bridgeManager = NowJsBridgeManager()
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let messageHandler = ScriptMessageHandlerProxy()
        let schemeHandler = LocalSchemeHandler()

        configuration.userContentController = userContentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: WilmarLocalSource.scheme)

        let nativeWebView = WKWebView(frame: .zero, configuration: configuration)
        self.bridgeManager = bridgeManager
        self.nativeWebView = nativeWebView
        self.messageHandler = messageHandler
        self.schemeHandler = schemeHandler

        super.init(coder: coder)
        setupWebView(userContentController: userContentController)
    }

    public func load(url: URL) {
        nativeWebView.load(URLRequest(url: url))
    }

    public func load(source: WilmarLocalSource) {
        load(url: source.url)
    }

    public func evaluateJavaScript(_ script: String) async {
        onJavaScriptEvaluation?(script)
        await MainActor.run { [weak nativeWebView] in
            nativeWebView?.evaluateJavaScript(script)
        }
    }

    public func syncCookies(_ cookies: [HTTPCookie]) async {
        let store = nativeWebView.configuration.websiteDataStore.httpCookieStore
        for cookie in cookies {
            await withCheckedContinuation { continuation in
                store.setCookie(cookie) {
                    continuation.resume()
                }
            }
        }
    }

    public var canGoBack: Bool { nativeWebView.canGoBack }

    public func goBack() {
        nativeWebView.goBack()
    }

    public func dispose() {
        progressObserver?.invalidate()
        nativeWebView.navigationDelegate = nil
        nativeWebView.uiDelegate = nil
        nativeWebView.configuration.userContentController.removeScriptMessageHandler(forName: NowHybrid.currentConfig.bridgeName)
        nativeWebView.stopLoading()
    }

    private func setupWebView(userContentController: WKUserContentController) {
        nativeWebView.translatesAutoresizingMaskIntoConstraints = false
        nativeWebView.scrollView.contentInsetAdjustmentBehavior = .never
        addSubview(nativeWebView)
        NSLayoutConstraint.activate([
            nativeWebView.topAnchor.constraint(equalTo: topAnchor),
            nativeWebView.leadingAnchor.constraint(equalTo: leadingAnchor),
            nativeWebView.trailingAnchor.constraint(equalTo: trailingAnchor),
            nativeWebView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        messageHandler.onMessage = { [weak self] body in
            guard let self else {
                return
            }
            Task {
                await self.bridgeManager.dispatch(messageBody: body, on: self)
            }
        }

        userContentController.add(messageHandler, name: NowHybrid.currentConfig.bridgeName)
        userContentController.addUserScript(Self.bridgeBootstrapScript(named: NowHybrid.currentConfig.bridgeName))

        if #available(iOS 16.4, *) {
            nativeWebView.isInspectable = NowHybrid.currentConfig.isInspectable
        }

        nativeWebView.navigationDelegate = WebViewNavigationDelegate(owner: self)
        nativeWebView.uiDelegate = WebViewUIDelegate(owner: self)
        progressObserver = nativeWebView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor [weak self, weak webView] in
                guard let self, let webView else {
                    return
                }
                self.onProgressChanged?(Int(webView.estimatedProgress * 100))
            }
        }
    }

    private static func bridgeBootstrapScript(named bridgeName: String) -> WKUserScript {
        let source = """
        (function() {
          var callbackStore = {};
          function resolvePath(path) {
            if (!path) { return null; }
            var normalized = path.indexOf('window.') === 0 ? path.substring(7) : path;
            return normalized.split('.').reduce(function(current, key) {
              return current ? current[key] : undefined;
            }, window);
          }
          function receiveResponse(callbackId, response) {
            var callback = callbackStore[callbackId] || resolvePath(callbackId);
            if (typeof callback === 'function') {
              callback(response);
            }
            if (callbackStore[callbackId]) {
              delete callbackStore[callbackId];
            }
          }
          window.__nowHybridReceiveResponse = receiveResponse;
          window['\(bridgeName)'] = window['\(bridgeName)'] || {};
          window['\(bridgeName)'].invokeNativeMethod = function(data, callback) {
            var payload = (typeof data === 'string') ? { methodName: data } : (data || {});
            var callbackId = payload.callbackId || null;
            if (typeof callback === 'function') {
              callbackId = callbackId || "__now_cb_" + Date.now() + "_" + Math.random().toString(36).slice(2);
              callbackStore[callbackId] = callback;
            }
            window.webkit.messageHandlers['\(bridgeName)'].postMessage({
              methodName: payload.methodName || payload.eventName || payload.method || "",
              params: payload.params === undefined ? null : payload.params,
              callbackId: callbackId,
              oldVersion: !!payload.oldVersion
            });
          };
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}

public struct WilmarHybridView: UIViewRepresentable {
    private let webView: WilmarHybridWebView

    public init(webView: WilmarHybridWebView) {
        self.webView = webView
    }

    public func makeUIView(context: Context) -> WilmarHybridWebView {
        webView
    }

    public func updateUIView(_ uiView: WilmarHybridWebView, context: Context) {}
}
#else
public final class WilmarHybridWebView: @unchecked Sendable {
    public var onProgressChanged: ((Int) -> Void)?
    public var onFullScreenChanged: ((Bool) -> Void)?
    public var onJavaScriptEvaluation: ((String) -> Void)?
    public let bridgeManager: NowJsBridgeManager
    public private(set) var lastLoadedURL: URL?

    public init(bridgeManager: NowJsBridgeManager = NowJsBridgeManager()) {
        self.bridgeManager = bridgeManager
    }

    public func load(url: URL) {
        lastLoadedURL = url
    }

    public func load(source: WilmarLocalSource) {
        load(url: source.url)
    }

    public func evaluateJavaScript(_ script: String) async {
        onJavaScriptEvaluation?(script)
    }
    public func syncCookies(_ cookies: [HTTPCookie]) async {}
    public var canGoBack: Bool { false }
    public func goBack() {}
    public func dispose() {}
}
#endif

#if canImport(UIKit) && canImport(WebKit)
private final class ScriptMessageHandlerProxy: NSObject, WKScriptMessageHandler {
    var onMessage: ((Any) -> Void)?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        onMessage?(message.body)
    }
}

private final class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var owner: WilmarHybridWebView?

    init(owner: WilmarHybridWebView) {
        self.owner = owner
    }
}

private final class WebViewUIDelegate: NSObject, WKUIDelegate {
    weak var owner: WilmarHybridWebView?

    init(owner: WilmarHybridWebView) {
        self.owner = owner
    }

    func webViewDidClose(_ webView: WKWebView) {
        owner?.onFullScreenChanged?(false)
    }

    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.grant)
    }
}

private final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let source = WilmarLocalSource(url: urlSchemeTask.request.url ?? URL(fileURLWithPath: "")),
              let fileURL = source.resolvedFileURL(),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(NSError(domain: "NowHybrid.LocalSource", code: 404))
            return
        }

        let response = URLResponse(
            url: source.url,
            mimeType: mimeType(for: fileURL),
            expectedContentLength: data.count,
            textEncodingName: nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}

    private func mimeType(for url: URL) -> String {
        #if canImport(UniformTypeIdentifiers)
        if let type = UTType(filenameExtension: url.pathExtension),
           let mimeType = type.preferredMIMEType {
            return mimeType
        }
        #endif

        switch url.pathExtension.lowercased() {
        case "html", "htm":
            return "text/html"
        case "js":
            return "application/javascript"
        case "css":
            return "text/css"
        case "json":
            return "application/json"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "svg":
            return "image/svg+xml"
        case "mp4":
            return "video/mp4"
        default:
            return "application/octet-stream"
        }
    }
}
#endif
